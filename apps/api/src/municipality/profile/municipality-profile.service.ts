import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';
import {
  MunicipalityProfile,
  MunicipalityProfilePayload,
} from './municipality-profile.types';

@Injectable()
export class MunicipalityProfileService {
  async getProfile(tenantId: string): Promise<MunicipalityProfile> {
    const filePath = this.getFilePath(tenantId);
    await this.ensureTenantDir(filePath);

    try {
      const file = await fs.readFile(filePath, 'utf8');
      return JSON.parse(file) as MunicipalityProfile;
    } catch {
      const seeded = this.createSeedProfile(tenantId);
      await this.writeFileAtomic(filePath, seeded);
      return seeded;
    }
  }

  async upsertProfile(
    tenantId: string,
    payload: MunicipalityProfilePayload,
  ): Promise<MunicipalityProfile> {
    const existing = await this.getProfile(tenantId);
    const now = new Date().toISOString();

    const updated: MunicipalityProfile = {
      tenantId,
      name: payload.name.trim(),
      address: {
        street: payload.address.street.trim(),
        zip: payload.address.zip.trim(),
        city: payload.address.city.trim(),
      },
      phone: payload.phone.trim(),
      fax: payload.fax.trim(),
      email: payload.email.trim(),
      websiteUrl: payload.websiteUrl.trim(),
      openingHours: payload.openingHours,
      importantLinks: payload.importantLinks,
      emergencyNumbers: payload.emergencyNumbers,
      createdAt: existing.createdAt,
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
      'municipality-profile.json',
    );
  }

  private async ensureTenantDir(filePath: string) {
    const directory = dirname(filePath);
    await fs.mkdir(directory, { recursive: true });
  }

  private async writeFileAtomic(
    filePath: string,
    data: MunicipalityProfile,
  ) {
    const tempPath = `${filePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, filePath);
  }

  private createSeedProfile(tenantId: string): MunicipalityProfile {
    const now = new Date().toISOString();
    return {
      tenantId,
      name: `Gemeinde ${tenantId}`,
      address: {
        street: '',
        zip: '',
        city: '',
      },
      phone: '',
      fax: '',
      email: '',
      websiteUrl: '',
      openingHours: [],
      importantLinks: [],
      emergencyNumbers: [],
      createdAt: now,
      updatedAt: now,
    };
  }
}
