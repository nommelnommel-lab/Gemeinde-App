import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  TooManyRequestsException,
  UnauthorizedException,
} from '@nestjs/common';
import { randomBytes, createHash } from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { ActivationCodesService } from './activation-codes.service';
import { ResidentsService } from './residents.service';
import { RefreshTokensService } from './refresh-tokens.service';
import { UsersService } from './users.service';
import { AuthUser, Resident } from './auth.types';

const ACCESS_TOKEN_TTL_MINUTES = 15;
const REFRESH_TOKEN_TTL_DAYS = 30;
const MAX_ATTEMPTS = 5;
const ATTEMPT_WINDOW_MS = 15 * 60 * 1000;

@Injectable()
export class AuthService {
  private readonly ipAttempts = new Map<
    string,
    { count: number; resetAt: number }
  >();

  constructor(
    private readonly activationCodesService: ActivationCodesService,
    private readonly residentsService: ResidentsService,
    private readonly usersService: UsersService,
    private readonly refreshTokensService: RefreshTokensService,
  ) {}

  async activate(
    tenantId: string,
    payload: {
      activationCode: string;
      email: string;
      password: string;
      postalCode: string;
      houseNumber: string;
    },
    ipAddress: string,
  ) {
    this.enforceIpLimit(ipAddress);

    const codeHash = this.activationCodesService.hashCode(
      payload.activationCode.trim(),
    );
    const activation = await this.activationCodesService.findByHash(
      tenantId,
      codeHash,
    );
    if (!activation) {
      this.registerIpAttempt(ipAddress);
      throw new UnauthorizedException('Aktivierungscode ist ungültig');
    }

    const now = new Date();
    const nextAttemptCount = this.registerCodeAttempt(activation);
    await this.activationCodesService.update(tenantId, activation.id, {
      attemptCount: nextAttemptCount,
      lastAttemptAt: now.toISOString(),
    });

    const resident = await this.residentsService.getById(
      tenantId,
      activation.residentId,
    );
    this.verifyResidentAddress(resident, payload.postalCode, payload.houseNumber);

    if (activation.revokedAt) {
      throw new ForbiddenException('Aktivierungscode wurde widerrufen');
    }
    if (activation.usedAt) {
      throw new ForbiddenException('Aktivierungscode wurde bereits genutzt');
    }
    if (Date.parse(activation.expiresAt) <= now.getTime()) {
      throw new ForbiddenException('Aktivierungscode ist abgelaufen');
    }

    const normalizedEmail = this.normalizeEmail(payload.email);
    const existingUser = await this.usersService.findByEmail(
      tenantId,
      normalizedEmail,
    );
    if (existingUser) {
      throw new BadRequestException('Email ist bereits registriert');
    }

    const existingByResident = await this.usersService.findByResidentId(
      tenantId,
      resident.id,
    );
    if (existingByResident) {
      throw new BadRequestException('Bewohner ist bereits aktiviert');
    }

    const passwordHash = await bcrypt.hash(payload.password, 10);
    const user = await this.usersService.create(tenantId, {
      residentId: resident.id,
      email: normalizedEmail,
      passwordHash,
      emailVerifiedAt: now.toISOString(),
    });

    await this.activationCodesService.update(tenantId, activation.id, {
      usedAt: now.toISOString(),
      attemptCount: nextAttemptCount,
      lastAttemptAt: now.toISOString(),
    });

    this.registerIpAttempt(ipAddress);

    return this.buildAuthResponse(tenantId, user, resident);
  }

  async login(
    tenantId: string,
    payload: { email: string; password: string },
    ipAddress: string,
  ) {
    this.enforceIpLimit(ipAddress);

    const normalizedEmail = this.normalizeEmail(payload.email);
    const user = await this.usersService.findByEmail(tenantId, normalizedEmail);
    if (!user) {
      this.registerIpAttempt(ipAddress);
      throw new UnauthorizedException('Login fehlgeschlagen');
    }

    const ok = await bcrypt.compare(payload.password, user.passwordHash);
    if (!ok) {
      this.registerIpAttempt(ipAddress);
      throw new UnauthorizedException('Login fehlgeschlagen');
    }

    const resident = await this.residentsService.getById(tenantId, user.residentId);
    return this.buildAuthResponse(tenantId, user, resident);
  }

  async refresh(tenantId: string, refreshToken: string) {
    const tokenHash = this.hashToken(refreshToken);
    const token = await this.refreshTokensService.findByHash(tenantId, tokenHash);
    if (!token || token.revokedAt) {
      throw new UnauthorizedException('Refresh token ungültig');
    }
    const now = new Date();
    if (Date.parse(token.expiresAt) <= now.getTime()) {
      throw new UnauthorizedException('Refresh token abgelaufen');
    }

    const user = await this.usersService.getById(tenantId, token.userId);
    const resident = await this.residentsService.getById(tenantId, user.residentId);

    await this.refreshTokensService.revoke(tenantId, token.id);
    const nextRefresh = await this.issueRefreshToken(tenantId, user.id, now);
    const accessToken = this.issueAccessToken(user, now);

    return {
      accessToken,
      refreshToken: nextRefresh.plaintext,
    };
  }

  async logout(tenantId: string, refreshToken: string) {
    const tokenHash = this.hashToken(refreshToken);
    const token = await this.refreshTokensService.findByHash(tenantId, tokenHash);
    if (token && !token.revokedAt) {
      await this.refreshTokensService.revoke(tenantId, token.id);
    }
    return { ok: true };
  }

  private async buildAuthResponse(
    tenantId: string,
    user: AuthUser,
    resident: Resident,
  ) {
    const now = new Date();
    const accessToken = this.issueAccessToken(user, now);
    const refreshToken = await this.issueRefreshToken(tenantId, user.id, now);
    return {
      accessToken,
      refreshToken: refreshToken.plaintext,
      user: {
        id: user.id,
        tenantId: user.tenantId,
        residentId: user.residentId,
        displayName: this.buildDisplayName(resident),
        email: user.email,
      },
    };
  }

  private buildDisplayName(resident: Resident) {
    const lastInitial = resident.lastName.trim().charAt(0).toUpperCase();
    return `${resident.firstName.trim()} ${lastInitial}.`;
  }

  private issueAccessToken(user: AuthUser, now: Date) {
    const secret = this.getJwtSecret();
    return jwt.sign(
      {
        sub: user.id,
        tenantId: user.tenantId,
        residentId: user.residentId,
        email: user.email,
      },
      secret,
      { expiresIn: `${ACCESS_TOKEN_TTL_MINUTES}m`, issuer: 'gemeinde-api' },
    );
  }

  private async issueRefreshToken(tenantId: string, userId: string, now: Date) {
    const plaintext = randomBytes(32).toString('base64url');
    const expires = new Date(now);
    expires.setDate(expires.getDate() + REFRESH_TOKEN_TTL_DAYS);
    const tokenHash = this.hashToken(plaintext);
    await this.refreshTokensService.create(tenantId, {
      userId,
      tokenHash,
      expiresAt: expires.toISOString(),
    });
    return { plaintext };
  }

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private verifyResidentAddress(
    resident: Resident,
    postalCode: string,
    houseNumber: string,
  ) {
    if (
      this.normalizeAddress(resident.postalCode) !==
        this.normalizeAddress(postalCode) ||
      this.normalizeAddress(resident.houseNumber) !==
        this.normalizeAddress(houseNumber)
    ) {
      throw new ForbiddenException('Adresse stimmt nicht überein');
    }
  }

  private normalizeAddress(value: string) {
    return value.trim().toUpperCase();
  }

  private hashToken(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private getJwtSecret() {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('JWT_SECRET fehlt');
    }
    return secret;
  }

  private enforceIpLimit(ip: string) {
    const entry = this.ipAttempts.get(ip);
    if (!entry) {
      return;
    }
    if (Date.now() > entry.resetAt) {
      this.ipAttempts.delete(ip);
      return;
    }
    if (entry.count >= MAX_ATTEMPTS) {
      throw new TooManyRequestsException('Zu viele Versuche. Bitte warten.');
    }
  }

  private registerIpAttempt(ip: string) {
    const now = Date.now();
    const entry = this.ipAttempts.get(ip);
    if (!entry || now > entry.resetAt) {
      this.ipAttempts.set(ip, { count: 1, resetAt: now + ATTEMPT_WINDOW_MS });
      return;
    }
    entry.count += 1;
  }

  private registerCodeAttempt(activation: {
    attemptCount: number;
    lastAttemptAt?: string;
  }) {
    if (!activation.lastAttemptAt) {
      return 1;
    }
    const lastAttempt = Date.parse(activation.lastAttemptAt);
    if (Number.isNaN(lastAttempt)) {
      return 1;
    }
    if (Date.now() - lastAttempt > ATTEMPT_WINDOW_MS) {
      return 1;
    }
    if (activation.attemptCount >= MAX_ATTEMPTS) {
      throw new TooManyRequestsException('Zu viele Versuche. Bitte warten.');
    }
    return activation.attemptCount + 1;
  }
}
