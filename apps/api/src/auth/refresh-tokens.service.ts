import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { RefreshToken } from './auth.types';

@Injectable()
export class RefreshTokensService {
  private readonly repository = new TenantFileRepository<RefreshToken>(
    'refresh-tokens',
  );

  async create(
    tenantId: string,
    payload: {
      userId: string;
      tokenHash: string;
      expiresAt: string;
    },
  ): Promise<RefreshToken> {
    const tokens = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const token: RefreshToken = {
      id: randomUUID(),
      tenantId,
      userId: payload.userId,
      tokenHash: payload.tokenHash,
      expiresAt: payload.expiresAt,
      createdAt: now,
    };
    tokens.push(token);
    await this.repository.setAll(tenantId, tokens);
    return token;
  }

  async findByHash(
    tenantId: string,
    tokenHash: string,
  ): Promise<RefreshToken | undefined> {
    const tokens = await this.repository.getAll(tenantId);
    return tokens.find((entry) => entry.tokenHash === tokenHash);
  }

  async revoke(tenantId: string, id: string): Promise<RefreshToken> {
    const tokens = await this.repository.getAll(tenantId);
    const index = tokens.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Refresh-Token nicht gefunden');
    }
    const updated: RefreshToken = {
      ...tokens[index],
      revokedAt: new Date().toISOString(),
    };
    tokens[index] = updated;
    await this.repository.setAll(tenantId, tokens);
    return updated;
  }
}
