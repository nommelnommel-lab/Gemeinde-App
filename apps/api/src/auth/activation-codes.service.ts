import { Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes, randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { ActivationCode } from './activation-codes.model';
import {
  formatActivationCode,
  hashActivationCode,
  normalizeActivationCode,
} from './auth.normalize';

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
    const now = new Date().toISOString();
    const updatedCodes = codes.map((entry) => {
      if (
        entry.residentId === residentId &&
        !entry.usedAt &&
        !entry.revokedAt &&
        Date.parse(entry.expiresAt) > Date.now()
      ) {
        return {
          ...entry,
          revokedAt: now,
        };
      }
      return entry;
    });
    let code = '';
    let canonicalCode = '';
    let codeHash = '';

    for (let attempt = 0; attempt < 5; attempt += 1) {
      canonicalCode = normalizeActivationCode(this.generateCode());
      codeHash = hashActivationCode(tenantId, canonicalCode);
      const exists = updatedCodes.some(
        (entry) =>
          entry.tenantId === tenantId && entry.codeHash === codeHash,
      );
      if (!exists) {
        code = formatActivationCode(canonicalCode);
        break;
      }
    }

    if (!codeHash || !code) {
      throw new Error('Aktivierungscode konnte nicht erzeugt werden');
    }

    const activation: ActivationCode = {
      id: randomUUID(),
      tenantId,
      residentId,
      codeHash,
      expiresAt: expiresAt.toISOString(),
      attemptCount: 0,
      createdAt: now,
    };

    updatedCodes.push(activation);
    await this.repository.setAll(tenantId, updatedCodes);
    if (process.env.NODE_ENV === 'development') {
      // eslint-disable-next-line no-console
      console.info('[activation_code_created]', {
        tenantId,
        activationCodeLength: canonicalCode.length,
      });
    }
    return { code, activation };
  }

  async findByHash(
    tenantId: string,
    codeHash: string,
  ): Promise<ActivationCode | undefined> {
    const codes = await this.repository.getAll(tenantId);
    const match = codes.find(
      (entry) => entry.tenantId === tenantId && entry.codeHash === codeHash,
    );
    return match ? this.normalizeActivationCode(match) : undefined;
  }

  async findActiveByResident(
    tenantId: string,
    residentId: string,
    now: Date = new Date(),
  ): Promise<ActivationCode | undefined> {
    const codes = await this.repository.getAll(tenantId);
    const match = codes
      .map((entry) => this.normalizeActivationCode(entry))
      .filter((entry) => entry.residentId === residentId)
      .find((entry) => {
        if (entry.usedAt || entry.revokedAt) {
          return false;
        }
        return Date.parse(entry.expiresAt) > now.getTime();
      });
    return match;
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
    const normalized = this.normalizeActivationCode(codes[index]);
    const updated: ActivationCode = {
      ...normalized,
      ...patch,
    };
    codes[index] = updated;
    await this.repository.setAll(tenantId, codes);
    return updated;
  }

  private generateCode() {
    return randomBytes(4).toString('hex').toUpperCase();
  }

  private normalizeActivationCode(entry: ActivationCode): ActivationCode {
    const raw = entry as ActivationCode & {
      resident_id?: string;
      residentID?: string;
    };
    return {
      ...entry,
      residentId: entry.residentId ?? raw.resident_id ?? raw.residentID,
    };
  }
}
