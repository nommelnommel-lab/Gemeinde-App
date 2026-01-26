import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes, randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import {
  formatTouristCode,
  hashTouristCode,
  normalizeTouristCode,
} from './auth.normalize';
import {
  TouristAccessCode,
  TouristAccessCodeStatus,
} from './tourist-access-codes.model';

@Injectable()
export class TouristAccessCodesService {
  private readonly repository = new TenantFileRepository<TouristAccessCode>(
    'tourist-access-codes',
  );

  async generateCodes(params: {
    tenantId: string;
    durationDays: 7 | 14 | 30;
    amount: number;
  }) {
    const { tenantId, durationDays, amount } = params;
    if (!Number.isInteger(amount) || amount < 1 || amount > 1000) {
      throw new BadRequestException('amount muss zwischen 1 und 1000 liegen');
    }
    if (![7, 14, 30].includes(durationDays)) {
      throw new BadRequestException('durationDays muss 7, 14 oder 30 sein');
    }

    const existing = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const generated: string[] = [];

    for (let index = 0; index < amount; index += 1) {
      let code = '';
      let codeHash = '';
      for (let attempt = 0; attempt < 10; attempt += 1) {
        const candidate = randomBytes(6).toString('hex').toUpperCase();
        const formatted = formatTouristCode(candidate);
        const normalized = normalizeTouristCode(formatted);
        if (!normalized) {
          continue;
        }
        const hash = hashTouristCode(tenantId, normalized);
        const exists = existing.some(
          (entry) =>
            entry.tenantId === tenantId && entry.codeHash === hash,
        );
        if (!exists) {
          code = formatted;
          codeHash = hash;
          break;
        }
      }
      if (!codeHash || !code) {
        throw new Error('Tourist-Code konnte nicht erzeugt werden');
      }

      const record: TouristAccessCode = {
        id: randomUUID(),
        tenantId,
        codeHash,
        durationDays,
        status: TouristAccessCodeStatus.ACTIVE,
        redeemedAt: null,
        redeemedByDeviceId: null,
        createdAt: now,
      };
      existing.push(record);
      generated.push(code);
    }

    await this.repository.setAll(tenantId, existing);
    return generated;
  }

  async listCodes(params: {
    tenantId: string;
    status?: TouristAccessCodeStatus;
    durationDays?: 7 | 14 | 30;
  }) {
    const { tenantId, status, durationDays } = params;
    const codes = await this.repository.getAll(tenantId);
    return codes.filter((entry) => {
      if (entry.tenantId !== tenantId) {
        return false;
      }
      if (status && entry.status !== status) {
        return false;
      }
      if (durationDays && entry.durationDays !== durationDays) {
        return false;
      }
      return true;
    });
  }

  async revoke(tenantId: string, id: string) {
    const codes = await this.repository.getAll(tenantId);
    const index = codes.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Tourist-Code nicht gefunden');
    }
    const record = codes[index];
    if (record.status === TouristAccessCodeStatus.REVOKED) {
      return record;
    }
    if (record.status !== TouristAccessCodeStatus.ACTIVE) {
      throw new ConflictException('Tourist-Code ist nicht aktiv');
    }
    const updated: TouristAccessCode = {
      ...record,
      status: TouristAccessCodeStatus.REVOKED,
    };
    codes[index] = updated;
    await this.repository.setAll(tenantId, codes);
    return updated;
  }

  async redeem(params: {
    tenantId: string;
    code: string;
    deviceId: string;
  }) {
    const { tenantId, code, deviceId } = params;
    const normalized = normalizeTouristCode(code);
    if (!normalized || !/^[A-Z0-9]{12}$/.test(normalized)) {
      throw new BadRequestException('Code-Format ungültig');
    }
    if (!deviceId || deviceId.trim().length < 3) {
      throw new BadRequestException('deviceId ist ungültig');
    }
    const codeHash = hashTouristCode(tenantId, normalized);
    const codes = await this.repository.getAll(tenantId);
    const index = codes.findIndex(
      (entry) =>
        entry.tenantId === tenantId && entry.codeHash === codeHash,
    );
    if (index === -1) {
      throw new NotFoundException('Code nicht gefunden');
    }
    const record = codes[index];
    if (record.status !== TouristAccessCodeStatus.ACTIVE) {
      throw new ConflictException('Code ist nicht mehr aktiv');
    }

    const now = new Date().toISOString();
    const updated: TouristAccessCode = {
      ...record,
      status: TouristAccessCodeStatus.REDEEMED,
      redeemedAt: now,
      redeemedByDeviceId: deviceId.trim(),
    };
    codes[index] = updated;
    await this.repository.setAll(tenantId, codes);
    return updated;
  }
}
