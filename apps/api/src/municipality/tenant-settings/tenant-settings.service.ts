import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';
import {
  TenantSettings,
  TenantSettingsPayload,
} from './tenant-settings.types';

@Injectable()
export class TenantSettingsService {
  async getSettings(tenantId: string): Promise<TenantSettings> {
    const filePath = this.getFilePath(tenantId);
    await this.ensureTenantDir(filePath);

    try {
      const file = await fs.readFile(filePath, 'utf8');
      return JSON.parse(file) as TenantSettings;
    } catch {
      const seeded = this.createSeedSettings(tenantId);
      await this.writeFileAtomic(filePath, seeded);
      return seeded;
    }
  }

  async upsertSettings(
    tenantId: string,
    payload: TenantSettingsPayload,
  ): Promise<TenantSettings> {
    const existing = await this.getSettings(tenantId);
    const now = new Date().toISOString();

    const updated: TenantSettings = {
      ...existing,
      tenantId,
      name: payload.name?.trim() || existing.name,
      contactEmail: payload.contactEmail?.trim() || existing.contactEmail,
      contactPhone: payload.contactPhone?.trim() || existing.contactPhone,
      websiteUrl: payload.websiteUrl?.trim() || existing.websiteUrl,
      address: payload.address?.trim() || existing.address,
      openingHoursJson: payload.openingHoursJson ?? existing.openingHoursJson,
      brandingJson: payload.brandingJson ?? existing.brandingJson,
      featureFlagsJson: payload.featureFlagsJson ?? existing.featureFlagsJson,
      updatedAt: now,
    };

    const filePath = this.getFilePath(tenantId);
    await this.writeFileAtomic(filePath, updated);
    return updated;
  }

  private getFilePath(tenantId: string) {
    return join(
      process.cwd(),
      'data',
      'tenants',
      tenantId,
      'settings.json',
    );
  }

  private async ensureTenantDir(filePath: string) {
    const directory = dirname(filePath);
    await fs.mkdir(directory, { recursive: true });
  }

  private async writeFileAtomic(filePath: string, data: TenantSettings) {
    const tempPath = `${filePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, filePath);
  }

  private createSeedSettings(tenantId: string): TenantSettings {
    const now = new Date().toISOString();
    if (tenantId === 'hilders') {
      return {
        tenantId,
        name: 'Gemeinde Hilders',
        contactEmail: 'info@gemeinde-hilders.de',
        contactPhone: '+49 6681 9605-0',
        websiteUrl: 'https://www.hilders.de',
        address: 'Marktstraße 2, 36115 Hilders',
        openingHoursJson: [
          { day: 'Mon', opens: '08:30', closes: '12:30' },
          { day: 'Tue', opens: '08:30', closes: '12:30' },
          { day: 'Wed', opens: '08:30', closes: '12:30' },
          { day: 'Thu', opens: '08:30', closes: '12:30' },
          { day: 'Fri', opens: '08:30', closes: '12:00' },
          { day: 'Sat', closed: true },
          { day: 'Sun', closed: true },
        ],
        brandingJson: {
          primaryColor: '#0B5AA5',
          secondaryColor: '#F2C94C',
          logoUrl: 'https://www.hilders.de/logo.png',
        },
        featureFlagsJson: {
          events: true,
          services: true,
          wastePickup: true,
        },
        createdAt: now,
        updatedAt: now,
      };
    }

    return {
      tenantId,
      name: `Gemeinde ${tenantId}`,
      contactEmail: 'kontakt@example.de',
      contactPhone: '+49 123 456 789',
      websiteUrl: 'https://www.beispiel-gemeinde.de',
      address: 'Kirchplatz 1, 12345 Musterstadt',
      openingHoursJson: [],
      brandingJson: {},
      featureFlagsJson: {},
      createdAt: now,
      updatedAt: now,
    };
  }
}
