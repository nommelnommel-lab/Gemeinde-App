import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';
import { TenantConfig } from './tenant.types';
import { TenantConfigDto } from './dto/tenant-config.dto';

@Injectable()
export class TenantConfigService {
  private readonly basePath = join(process.cwd(), 'data', 'tenants');

  async getConfig(tenantId: string): Promise<TenantConfig> {
    await this.ensureTenantDir(tenantId);
    const filePath = this.getConfigPath(tenantId);

    try {
      const file = await fs.readFile(filePath, 'utf8');
      return JSON.parse(file) as TenantConfig;
    } catch {
      const seeded = this.createSeedConfig(tenantId);
      await this.writeFileAtomic(filePath, seeded);
      return seeded;
    }
  }

  async updateConfig(
    tenantId: string,
    payload: TenantConfigDto,
  ): Promise<TenantConfig> {
    const existing = await this.getConfig(tenantId);
    const now = new Date().toISOString();
    const updated: TenantConfig = {
      tenantId,
      name: payload.name.trim(),
      contactPhone: payload.contactPhone.trim(),
      contactEmail: payload.contactEmail.trim(),
      websiteUrl: payload.websiteUrl.trim(),
      address: payload.address.trim(),
      openingHours: payload.openingHours.map((entry) => ({
        day: entry.day,
        opens: entry.opens,
        closes: entry.closes,
        note: entry.note?.trim() || undefined,
        closed: entry.closed ?? false,
      })),
      emergencyNumbers: payload.emergencyNumbers.map((entry) => ({
        label: entry.label.trim(),
        phone: entry.phone.trim(),
      })),
      createdAt: existing.createdAt,
      updatedAt: now,
    };

    const filePath = this.getConfigPath(tenantId);
    await this.writeFileAtomic(filePath, updated);
    return updated;
  }

  private getConfigPath(tenantId: string) {
    return join(this.basePath, tenantId, 'config.json');
  }

  private async ensureTenantDir(tenantId: string) {
    const directory = dirname(this.getConfigPath(tenantId));
    await fs.mkdir(directory, { recursive: true });
  }

  private async writeFileAtomic(filePath: string, data: TenantConfig) {
    const tempPath = `${filePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, filePath);
  }

  private createSeedConfig(tenantId: string): TenantConfig {
    const now = new Date().toISOString();
    return {
      tenantId,
      name: `Gemeinde ${tenantId}`,
      contactPhone: '+49 123 456 789',
      contactEmail: 'kontakt@example.de',
      websiteUrl: 'https://www.beispiel-gemeinde.de',
      address: 'Kirchplatz 1, 12345 Musterstadt',
      openingHours: [
        { day: 'Mon', opens: '09:00', closes: '17:00' },
        { day: 'Tue', opens: '09:00', closes: '17:00' },
        { day: 'Wed', opens: '09:00', closes: '17:00' },
        { day: 'Thu', opens: '09:00', closes: '17:00' },
        { day: 'Fri', opens: '09:00', closes: '15:00' },
        { day: 'Sat', closed: true, note: 'Nur nach Vereinbarung' },
        { day: 'Sun', closed: true, note: 'Gottesdienst siehe Aushang' },
      ],
      emergencyNumbers: [
        { label: 'Feuerwehr', phone: '112' },
        { label: 'Bürgerbüro', phone: '+49 123 987 654' },
      ],
      createdAt: now,
      updatedAt: now,
    };
  }
}
