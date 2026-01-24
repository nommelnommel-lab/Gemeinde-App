import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
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
import { hashActivationCode, normalizeActivationCode } from './auth.normalize';

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
  residentId?: string;
  codeHash: string;
  expiresAt: string;
  usedAt?: string | null;
  revokedAt?: string | null;
  createdAt?: string;
  createdBy?: string;
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
  private readonly logger = new Logger(AuthService.name);
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
    const rawActivationCode = this.requireString(
      payload.activationCode,
      'activationCode',
    );
    const activationCode = normalizeActivationCode(rawActivationCode);
    const codeHash = hashActivationCode(tenantId, activationCode);
    this.logger.log('[activate_attempt]', {
      tenantId,
      activationCodeInputLength: rawActivationCode.length,
      activationCodeNormalizedLength: activationCode.length,
      activationCodeHashPrefix: codeHash.slice(0, 8),
    });
    if (
      !activationCode ||
      activationCode.length < 8 ||
      !/^[A-Z0-9-]+$/.test(activationCode)
    ) {
      throw new BadRequestException('Aktivierungscode Format ungültig');
    }
    const email = this.normalizeEmail(payload.email);
    const password = this.requireString(payload.password, 'password');
    const postalCode = this.requireString(payload.postalCode, 'postalCode');
    const houseNumber = this.requireString(payload.houseNumber, 'houseNumber');

    this.activationLimiter.check(this.rateLimitKey(tenantId, email, clientKey));

    const { activationEntry, resident } =
      await this.findActivationWithResident(tenantId, codeHash);

    if (!activationEntry || !resident) {
      throw new UnauthorizedException('Aktivierungscode ungültig');
    }

    this.ensureActivationCodeValid(activationEntry);

    if (!this.matchesResident(resident, postalCode, houseNumber)) {
      throw new UnauthorizedException('PLZ/Hausnummer stimmt nicht');
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

    const codes = await this.activationCodes.getAll(tenantId);
    const updatedCodes = codes.map((code) => {
      const normalized = this.normalizeActivationCode(code);
      return normalized.id === activationEntry.id
        ? { ...normalized, usedAt: now }
        : normalized;
    });
    await this.activationCodes.setAll(tenantId, updatedCodes);

    return this.issueAuthResponse(tenantId, user, resident);
  }

  async createActivationCodes(params: {
    tenantId: string;
    count: number;
    expiresInDays: number;
    createdBy: string;
  }) {
    const { tenantId, count, expiresInDays, createdBy } = params;
    if (!Number.isInteger(count) || count < 1 || count > 100) {
      throw new BadRequestException('count muss zwischen 1 und 100 liegen');
    }
    if (
      !Number.isInteger(expiresInDays) ||
      expiresInDays < 1 ||
      expiresInDays > 3650
    ) {
      throw new BadRequestException(
        'expiresInDays muss zwischen 1 und 3650 liegen',
      );
    }

    const existingCodes = (await this.activationCodes.getAll(tenantId))
      .map((code) => this.normalizeActivationCode(code))
      .filter((code) => code.tenantId === tenantId);
    const existingHashes = new Set(existingCodes.map((code) => code.codeHash));
    const now = new Date();
    const nowIso = now.toISOString();
    const expiresAt = new Date(
      now.getTime() + expiresInDays * 24 * 60 * 60 * 1000,
    ).toISOString();

    const generated: { code: string; expiresAt: string }[] = [];
    const newRecords: ActivationCodeRecord[] = [];

    for (let i = 0; i < count; i += 1) {
      let code = '';
      let codeHash = '';
      let attempts = 0;
      do {
        if (attempts > 20) {
          throw new HttpException(
            'Aktivierungscode konnte nicht generiert werden',
            HttpStatus.INTERNAL_SERVER_ERROR,
          );
        }
        code = this.generateActivationCode(tenantId);
        const normalized = normalizeActivationCode(code);
        codeHash = hashActivationCode(tenantId, normalized);
        attempts += 1;
      } while (existingHashes.has(codeHash));

      existingHashes.add(codeHash);
      generated.push({ code, expiresAt });
      newRecords.push({
        id: randomUUID(),
        tenantId,
        codeHash,
        expiresAt,
        usedAt: null,
        createdAt: nowIso,
        createdBy,
      });
    }

    await this.activationCodes.setAll(tenantId, [
      ...existingCodes,
      ...newRecords,
    ]);

    return generated;
  }

  async createActivationCodeForResident(params: {
    tenantId: string;
    residentId: string;
    expiresAt: Date;
    createdBy: string;
  }): Promise<{ code: string; expiresAt: string }> {
    const { tenantId, residentId, expiresAt, createdBy } = params;
    const expiresAtIso = expiresAt.toISOString();
    if (Number.isNaN(Date.parse(expiresAtIso)) || Date.parse(expiresAtIso) <= Date.now()) {
      throw new BadRequestException('expiresAt ist ungültig');
    }

    const existingCodes = (await this.activationCodes.getAll(tenantId))
      .map((code) => this.normalizeActivationCode(code))
      .filter((code) => code.tenantId === tenantId);
    const existingHashes = new Set(existingCodes.map((code) => code.codeHash));
    const nowIso = new Date().toISOString();

    let code = '';
    let codeHash = '';
    let attempts = 0;
    do {
      if (attempts > 20) {
        throw new HttpException(
          'Aktivierungscode konnte nicht generiert werden',
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }
      code = this.generateActivationCode(tenantId);
      const normalized = normalizeActivationCode(code);
      codeHash = hashActivationCode(tenantId, normalized);
      attempts += 1;
    } while (existingHashes.has(codeHash));

    const record: ActivationCodeRecord = {
      id: randomUUID(),
      tenantId,
      residentId,
      codeHash,
      expiresAt: expiresAtIso,
      usedAt: null,
      createdAt: nowIso,
      createdBy,
    };

    await this.activationCodes.setAll(tenantId, [...existingCodes, record]);

    if (process.env.NODE_ENV === 'development') {
      // eslint-disable-next-line no-console
      console.info('[activation_code_issued]', {
        tenantId,
        residentId,
        expiresAt: expiresAtIso,
        createdBy,
      });
    }

    return { code, expiresAt: expiresAtIso };
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

  private normalizeActivationCode(entry: ActivationCodeRecord) {
    const raw = entry as ActivationCodeRecord & {
      resident_id?: string;
      residentID?: string;
    };
    return {
      ...entry,
      residentId: entry.residentId ?? raw.resident_id ?? raw.residentID,
    };
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

  private async findActivationWithResident(tenantId: string, codeHash: string) {
    const [codes, residents] = await Promise.all([
      this.activationCodes.getAll(tenantId),
      this.residents.getAll(tenantId),
    ]);
    const activationEntry = codes
      .map((code) => this.normalizeActivationCode(code))
      .find(
        (code) => code.tenantId === tenantId && code.codeHash === codeHash,
      );
    if (!activationEntry?.residentId) {
      return { activationEntry, resident: undefined };
    }
    const resident = residents.find(
      (entry) => entry.id === activationEntry.residentId,
    );
    return { activationEntry, resident };
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

  private generateActivationCode(tenantId: string) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const prefix = tenantId
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '')
      .slice(0, 4);
    const usePrefix = prefix.length >= 2;
    const segments = [];
    const segmentCount = usePrefix ? 2 : 3;

    for (let i = 0; i < segmentCount; i += 1) {
      let segment = '';
      for (let j = 0; j < 4; j += 1) {
        const index = randomBytes(1)[0] % alphabet.length;
        segment += alphabet[index];
      }
      segments.push(segment);
    }

    if (usePrefix) {
      return `${prefix}-${segments.join('-')}`;
    }

    return segments.join('-');
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
