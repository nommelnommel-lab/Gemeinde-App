import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHash, randomBytes, randomUUID } from 'crypto';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { ActivateDto } from './dto/activate.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { AuthResponse, AuthUserView, JwtAccessPayload } from './auth.types';

type ResidentRecord = {
  id: string;
  tenantId: string;
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
};

type ActivationCodeRecord = {
  id: string;
  tenantId: string;
  residentId: string;
  codeHash: string;
  expiresAt: string;
  usedAt?: string | null;
  revokedAt?: string | null;
};

type UserRecord = {
  id: string;
  tenantId: string;
  residentId: string;
  email: string;
  passwordHash: string;
  createdAt: string;
  updatedAt: string;
};

type RefreshTokenRecord = {
  id: string;
  tenantId: string;
  userId: string;
  tokenHash: string;
  createdAt: string;
  expiresAt: string;
  revokedAt?: string | null;
};

const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
const REFRESH_TOKEN_TTL_DAYS = 30;
const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const RATE_LIMIT_MAX_ATTEMPTS = 5;

class InMemoryRateLimiter {
  private readonly attempts = new Map<
    string,
    { count: number; resetAt: number }
  >();

  constructor(private readonly max: number, private readonly windowMs: number) {}

  check(key: string) {
    const now = Date.now();
    const current = this.attempts.get(key);

    if (!current || current.resetAt <= now) {
      this.attempts.set(key, { count: 1, resetAt: now + this.windowMs });
      return;
    }

    if (current.count >= this.max) {
      throw new HttpException(
        'Zu viele Versuche, bitte später erneut versuchen',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    current.count += 1;
  }
}

@Injectable()
export class AuthService {
  private readonly activationCodes = new TenantFileRepository<ActivationCodeRecord>(
    'activation-codes',
  );
  private readonly residents = new TenantFileRepository<ResidentRecord>('residents');
  private readonly users = new TenantFileRepository<UserRecord>('users');
  private readonly refreshTokens = new TenantFileRepository<RefreshTokenRecord>(
    'refresh-tokens',
  );
  private readonly activationLimiter = new InMemoryRateLimiter(
    RATE_LIMIT_MAX_ATTEMPTS,
    RATE_LIMIT_WINDOW_MS,
  );
  private readonly loginLimiter = new InMemoryRateLimiter(
    RATE_LIMIT_MAX_ATTEMPTS,
    RATE_LIMIT_WINDOW_MS,
  );

  async activate(
    tenantId: string,
    payload: ActivateDto,
    clientKey: string,
  ): Promise<AuthResponse> {
    const activationCode = this.requireString(
      payload.activationCode,
      'activationCode',
    );
    const email = this.normalizeEmail(payload.email);
    const password = this.requireString(payload.password, 'password');
    const postalCode = this.requireString(payload.postalCode, 'postalCode');
    const houseNumber = this.requireString(payload.houseNumber, 'houseNumber');

    this.activationLimiter.check(this.rateLimitKey(tenantId, email, clientKey));

    const codeHash = this.hashToken(activationCode);
    const codes = await this.activationCodes.getAll(tenantId);
    const activationEntry = codes.find((code) => code.codeHash === codeHash);

    if (!activationEntry) {
      throw new UnauthorizedException('Aktivierungscode ungültig');
    }

    this.ensureActivationCodeValid(activationEntry);

    const resident = await this.findResident(
      tenantId,
      activationEntry.residentId,
    );

    if (!resident) {
      throw new NotFoundException('Bewohner nicht gefunden');
    }

    if (!this.matchesResident(resident, postalCode, houseNumber)) {
      throw new UnauthorizedException('Aktivierungsdaten stimmen nicht überein');
    }

    const existingUsers = await this.users.getAll(tenantId);
    if (existingUsers.some((user) => user.email === email)) {
      throw new ConflictException('E-Mail ist bereits registriert');
    }
    if (existingUsers.some((user) => user.residentId === resident.id)) {
      throw new ConflictException('Bewohner ist bereits aktiviert');
    }

    const now = new Date().toISOString();
    const user: UserRecord = {
      id: randomUUID(),
      tenantId,
      residentId: resident.id,
      email,
      passwordHash: await this.hashPassword(password),
      createdAt: now,
      updatedAt: now,
    };

    existingUsers.push(user);
    await this.users.setAll(tenantId, existingUsers);

    const updatedCodes = codes.map((code) =>
      code.id === activationEntry.id ? { ...code, usedAt: now } : code,
    );
    await this.activationCodes.setAll(tenantId, updatedCodes);

    return this.issueAuthResponse(tenantId, user, resident);
  }

  async login(
    tenantId: string,
    payload: LoginDto,
    clientKey: string,
  ): Promise<AuthResponse> {
    const email = this.normalizeEmail(payload.email);
    const password = this.requireString(payload.password, 'password');

    this.loginLimiter.check(this.rateLimitKey(tenantId, email, clientKey));

    const users = await this.users.getAll(tenantId);
    const user = users.find((entry) => entry.email === email);

    if (!user) {
      throw new UnauthorizedException('Login fehlgeschlagen');
    }

    const matches = await this.verifyPassword(password, user.passwordHash);
    if (!matches) {
      throw new UnauthorizedException('Login fehlgeschlagen');
    }

    await this.revokeUserRefreshTokens(tenantId, user.id);

    const resident = await this.findResident(tenantId, user.residentId);
    if (!resident) {
      throw new NotFoundException('Bewohner nicht gefunden');
    }

    return this.issueAuthResponse(tenantId, user, resident);
  }

  async refresh(
    tenantId: string,
    payload: RefreshDto,
  ): Promise<AuthResponse> {
    const refreshToken = this.requireString(payload.refreshToken, 'refreshToken');
    const tokenHash = this.hashToken(refreshToken);

    const tokens = await this.refreshTokens.getAll(tenantId);
    const existing = tokens.find((entry) => entry.tokenHash === tokenHash);

    if (!existing) {
      throw new UnauthorizedException('Refresh token ungültig');
    }

    this.ensureRefreshTokenValid(existing);

    const users = await this.users.getAll(tenantId);
    const user = users.find((entry) => entry.id === existing.userId);
    if (!user) {
      throw new UnauthorizedException('Refresh token ungültig');
    }

    const resident = await this.findResident(tenantId, user.residentId);
    if (!resident) {
      throw new NotFoundException('Bewohner nicht gefunden');
    }

    const now = new Date().toISOString();
    const updatedTokens = tokens.map((entry) =>
      entry.id === existing.id ? { ...entry, revokedAt: now } : entry,
    );
    await this.refreshTokens.setAll(tenantId, updatedTokens);

    return this.issueAuthResponse(tenantId, user, resident);
  }

  async logout(tenantId: string, payload: RefreshDto) {
    const refreshToken = this.requireString(payload.refreshToken, 'refreshToken');
    const tokenHash = this.hashToken(refreshToken);

    const tokens = await this.refreshTokens.getAll(tenantId);
    const existing = tokens.find((entry) => entry.tokenHash === tokenHash);

    if (!existing) {
      return { ok: true };
    }

    if (existing.revokedAt) {
      return { ok: true };
    }

    const now = new Date().toISOString();
    const updatedTokens = tokens.map((entry) =>
      entry.id === existing.id ? { ...entry, revokedAt: now } : entry,
    );
    await this.refreshTokens.setAll(tenantId, updatedTokens);

    return { ok: true };
  }

  private async issueAuthResponse(
    tenantId: string,
    user: UserRecord,
    resident: ResidentRecord,
  ): Promise<AuthResponse> {
    const displayName = this.createDisplayName(resident);
    const accessToken = this.createAccessToken({
      sub: user.id,
      tenantId,
      residentId: user.residentId,
      email: user.email,
    });

    const refreshToken = await this.createRefreshToken(tenantId, user.id);

    return {
      accessToken,
      refreshToken,
      user: this.toAuthUserView(user, displayName),
    };
  }

  private createAccessToken(payload: JwtAccessPayload) {
    return jwt.sign(payload, this.jwtSecret(), {
      expiresIn: ACCESS_TOKEN_TTL_SECONDS,
    });
  }

  private async createRefreshToken(tenantId: string, userId: string) {
    const rawToken = randomBytes(48).toString('base64url');
    const tokenHash = this.hashToken(rawToken);
    const now = new Date();
    const expiresAt = new Date(
      now.getTime() + REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000,
    );

    const record: RefreshTokenRecord = {
      id: randomUUID(),
      tenantId,
      userId,
      tokenHash,
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      revokedAt: null,
    };

    const tokens = await this.refreshTokens.getAll(tenantId);
    tokens.push(record);
    await this.refreshTokens.setAll(tenantId, tokens);

    return rawToken;
  }

  private async revokeUserRefreshTokens(tenantId: string, userId: string) {
    const tokens = await this.refreshTokens.getAll(tenantId);
    const now = new Date().toISOString();
    const updated = tokens.map((entry) =>
      entry.userId === userId && !entry.revokedAt
        ? { ...entry, revokedAt: now }
        : entry,
    );
    await this.refreshTokens.setAll(tenantId, updated);
  }

  private ensureActivationCodeValid(code: ActivationCodeRecord) {
    if (code.revokedAt) {
      throw new UnauthorizedException('Aktivierungscode ungültig');
    }

    if (code.usedAt) {
      throw new UnauthorizedException('Aktivierungscode ungültig');
    }

    const expiresAt = Date.parse(code.expiresAt);
    if (Number.isNaN(expiresAt) || expiresAt <= Date.now()) {
      throw new UnauthorizedException('Aktivierungscode ungültig');
    }
  }

  private ensureRefreshTokenValid(token: RefreshTokenRecord) {
    if (token.revokedAt) {
      throw new UnauthorizedException('Refresh token ungültig');
    }

    const expiresAt = Date.parse(token.expiresAt);
    if (Number.isNaN(expiresAt) || expiresAt <= Date.now()) {
      throw new UnauthorizedException('Refresh token ungültig');
    }
  }

  private async findResident(tenantId: string, residentId: string) {
    const residents = await this.residents.getAll(tenantId);
    return residents.find((resident) => resident.id === residentId);
  }

  private toAuthUserView(user: UserRecord, displayName: string): AuthUserView {
    return {
      id: user.id,
      tenantId: user.tenantId,
      residentId: user.residentId,
      displayName,
      email: user.email,
    };
  }

  private createDisplayName(resident: ResidentRecord) {
    const firstName = this.requireString(resident.firstName, 'firstName');
    const lastName = this.requireString(resident.lastName, 'lastName');
    return `${firstName} ${lastName.charAt(0)}.`;
  }

  private matchesResident(
    resident: ResidentRecord,
    postalCode: string,
    houseNumber: string,
  ) {
    return (
      this.normalizeComparable(resident.postalCode) ===
        this.normalizeComparable(postalCode) &&
      this.normalizeComparable(resident.houseNumber) ===
        this.normalizeComparable(houseNumber)
    );
  }

  private normalizeComparable(value: string) {
    return value.trim().toLowerCase();
  }

  private normalizeEmail(value: string) {
    const trimmed = this.requireString(value, 'email');
    return trimmed.toLowerCase();
  }

  private requireString(value: string | undefined | null, field: string) {
    if (typeof value !== 'string') {
      throw new BadRequestException(`${field} ist erforderlich`);
    }

    const trimmed = value.trim();
    if (!trimmed) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }

    return trimmed;
  }

  private hashToken(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private rateLimitKey(tenantId: string, email: string, clientKey: string) {
    if (!clientKey) {
      return `${tenantId}:${email}`;
    }
    return `${tenantId}:${email}:${clientKey}`;
  }

  private jwtSecret() {
    return process.env.JWT_SECRET || 'dev-secret-change-me';
  }

  private async hashPassword(password: string) {
    return bcrypt.hash(password, 10);
  }

  private async verifyPassword(password: string, hash: string) {
    return bcrypt.compare(password, hash);
  }
}
