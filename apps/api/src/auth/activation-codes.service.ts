import { Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes, randomUUID, createHash } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { ActivationCode } from './auth.types';

@Injectable()
export class ActivationCodesService {
  private readonly repository = new TenantFileRepository<ActivationCode>(
    'activation-codes',
  );

  async createCode(
    tenantId: string,
    residentId: string,
    expiresAt: Date,
  ): Promise<{ code: string; activation: ActivationCode }> {
    const codes = await this.repository.getAll(tenantId);
    let code = '';
    let codeHash = '';

    for (let attempt = 0; attempt < 5; attempt += 1) {
      code = this.generateCode();
      codeHash = this.hashCode(code);
      const exists = codes.some((entry) => entry.codeHash === codeHash);
      if (!exists) {
        break;
      }
    }

    if (!codeHash) {
      throw new Error('Aktivierungscode konnte nicht erzeugt werden');
    }

    const now = new Date().toISOString();
    const activation: ActivationCode = {
      id: randomUUID(),
      tenantId,
      residentId,
      codeHash,
      expiresAt: expiresAt.toISOString(),
      attemptCount: 0,
      createdAt: now,
    };

    codes.push(activation);
    await this.repository.setAll(tenantId, codes);
    return { code, activation };
  }

  async findByHash(
    tenantId: string,
    codeHash: string,
  ): Promise<ActivationCode | undefined> {
    const codes = await this.repository.getAll(tenantId);
    return codes.find((entry) => entry.codeHash === codeHash);
  }

  async findActiveByResident(
    tenantId: string,
    residentId: string,
    now: Date = new Date(),
  ): Promise<ActivationCode | undefined> {
    const codes = await this.repository.getAll(tenantId);
    return codes
      .filter((entry) => entry.residentId === residentId)
      .find((entry) => {
        if (entry.usedAt || entry.revokedAt) {
          return false;
        }
        return Date.parse(entry.expiresAt) > now.getTime();
      });
  }

  async update(
    tenantId: string,
    id: string,
    patch: Partial<ActivationCode>,
  ): Promise<ActivationCode> {
    const codes = await this.repository.getAll(tenantId);
    const index = codes.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Aktivierungscode nicht gefunden');
    }
    const updated: ActivationCode = {
      ...codes[index],
      ...patch,
    };
    codes[index] = updated;
    await this.repository.setAll(tenantId, codes);
    return updated;
  }

  hashCode(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }

  private generateCode() {
    return randomBytes(4).toString('hex').toUpperCase();
  }
}
