import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  MunicipalityWastePickup,
  MunicipalityWastePickupInput,
  WastePickupStatus,
} from './municipality-waste-pickups.types';

@Injectable()
export class MunicipalityWastePickupsService {
  private readonly repository = new TenantFileRepository<MunicipalityWastePickup>(
    'waste-pickups',
    (tenantId) => this.createSeedPickups(tenantId),
  );

  async list(
    tenantId: string,
    options: { district: string; from: Date; to: Date },
  ): Promise<MunicipalityWastePickup[]> {
    const pickups = await this.repository.getAll(tenantId);
    return pickups.filter((pickup) => {
      if (pickup.status !== 'PUBLISHED') {
        return false;
      }
      if (pickup.district !== options.district) {
        return false;
      }
      const pickupTime = Date.parse(pickup.pickupDate);
      if (pickupTime < options.from.getTime()) {
        return false;
      }
      if (pickupTime > options.to.getTime()) {
        return false;
      }
      return true;
    });
  }

  async bulkUpsert(
    tenantId: string,
    inputs: MunicipalityWastePickupInput[],
  ): Promise<{ inserted: number; skipped: number }> {
    const pickups = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    let inserted = 0;
    let skipped = 0;

    for (const input of inputs) {
      const exists = pickups.some(
        (pickup) =>
          pickup.tenantId === tenantId &&
          pickup.district === input.district &&
          pickup.wasteType === input.wasteType &&
          pickup.pickupDate === input.pickupDate,
      );
      if (exists) {
        skipped += 1;
        continue;
      }
      const pickup: MunicipalityWastePickup = {
        id: randomUUID(),
        tenantId,
        district: input.district,
        wasteType: input.wasteType,
        pickupDate: input.pickupDate,
        status: input.status ?? 'PUBLISHED',
        createdAt: now,
        updatedAt: now,
      };
      pickups.push(pickup);
      inserted += 1;
    }

    await this.repository.setAll(tenantId, pickups);
    return { inserted, skipped };
  }

  private createSeedPickups(tenantId: string): MunicipalityWastePickup[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date();
    const wasteTypes = ['Restmüll', 'Bio', 'Papier', 'Gelber Sack'];
    const pickups: MunicipalityWastePickup[] = [];
    for (let i = 0; i < 20; i += 1) {
      const date = new Date(now);
      date.setDate(date.getDate() + i * 3);
      pickups.push({
        id: randomUUID(),
        tenantId,
        district: 'Hilders-Zentrum',
        wasteType: wasteTypes[i % wasteTypes.length],
        pickupDate: date.toISOString().slice(0, 10),
        status: 'PUBLISHED',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
      });
    }
    return pickups;
  }
}
