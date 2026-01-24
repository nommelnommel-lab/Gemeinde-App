import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { promises as fs } from 'fs';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { Resident, ResidentStatus } from './residents.model';

@Injectable()
export class ResidentsService {
  private readonly repository = new TenantFileRepository<Resident>('residents');
  private readonly tenantsPath = join(process.cwd(), 'data', 'tenants');

  async createResident(
    tenantId: string,
    payload: {
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    },
  ): Promise<string> {
    const normalized = this.normalizeResident(payload);
    const existing = await this.findByAddress(
      tenantId,
      normalized.postalCode,
      normalized.houseNumber,
    );
    if (existing) {
      await this.update(tenantId, existing.id, normalized);
      return existing.id;
    }

    const resident = await this.create(tenantId, normalized);
    return resident.id;
  }

  async listResidents(
    tenantId: string,
    q?: string,
    limit = 50,
    postalCode?: string,
    houseNumber?: string,
    status?: ResidentStatus,
  ): Promise<
    Array<{
      id: string;
      displayName: string;
      status: ResidentStatus;
      createdAt: string;
      postalCode: string;
      houseNumber: string;
    }>
  > {
    const residents = await this.repository.getAll(tenantId);
    const cappedLimit = this.clampLimit(limit);
    const normalizedQuery = q ? this.normalizeQuery(q) : undefined;
    const normalizedPostal = postalCode
      ? this.normalizePostalCode(postalCode)
      : undefined;
    const normalizedHouse = houseNumber ? this.normalize(houseNumber) : undefined;
    const filtered = normalizedQuery
      ? residents.filter(
          (resident) =>
            this.normalize(resident.firstName).includes(normalizedQuery) ||
            this.normalize(resident.lastName).includes(normalizedQuery),
        )
      : residents;
    const filteredByPostal = normalizedPostal
      ? filtered.filter(
          (resident) =>
            this.normalizePostalCode(resident.postalCode) === normalizedPostal,
        )
      : filtered;
    const filteredByHouse = normalizedHouse
      ? filteredByPostal.filter(
          (resident) =>
            this.normalize(resident.houseNumber) === normalizedHouse,
        )
      : filteredByPostal;
    const filteredByStatus = status
      ? filteredByHouse.filter((resident) => resident.status === status)
      : filteredByHouse;

    return filteredByStatus.slice(0, cappedLimit).map((resident) => ({
      id: resident.id,
      displayName: this.displayName(resident.firstName, resident.lastName),
      status: resident.status,
      createdAt: resident.createdAt,
      postalCode: resident.postalCode,
      houseNumber: resident.houseNumber,
    }));
  }

  async bulkCreateResidents(
    tenantId: string,
    payload: Array<{
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    }>,
  ): Promise<{
    created: number;
    updated: number;
    failed: number;
    errors: Array<{ index: number; reason: string }>;
  }> {
    let created = 0;
    let updated = 0;
    const errors: Array<{ index: number; reason: string }> = [];

    for (let index = 0; index < payload.length; index += 1) {
      try {
        const entry = this.normalizeResident(payload[index]);
        const existing = await this.findByAddress(
          tenantId,
          entry.postalCode,
          entry.houseNumber,
        );
        if (existing) {
          await this.update(tenantId, existing.id, entry);
          updated += 1;
        } else {
          await this.create(tenantId, entry);
          created += 1;
        }
      } catch (error) {
        errors.push({
          index,
          reason: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    return { created, updated, failed: errors.length, errors };
  }

  normalizeResidentInput(payload: {
    firstName: string;
    lastName: string;
    postalCode: string;
    houseNumber: string;
  }) {
    return this.normalizeResident(payload);
  }

  async list(tenantId: string): Promise<Resident[]> {
    return this.repository.getAll(tenantId);
  }

  async create(
    tenantId: string,
    payload: {
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
      status?: ResidentStatus;
    },
  ): Promise<Resident> {
    const residents = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const resident: Resident = {
      id: randomUUID(),
      tenantId,
      firstName: payload.firstName,
      lastName: payload.lastName,
      postalCode: payload.postalCode,
      houseNumber: payload.houseNumber,
      status: payload.status ?? 'ACTIVE',
      createdAt: now,
      updatedAt: now,
    };
    residents.push(resident);
    await this.repository.setAll(tenantId, residents);
    return resident;
  }

  async update(
    tenantId: string,
    id: string,
    payload: {
      firstName?: string;
      lastName?: string;
      postalCode?: string;
      houseNumber?: string;
      status?: ResidentStatus;
    },
  ): Promise<Resident> {
    const residents = await this.repository.getAll(tenantId);
    const index = residents.findIndex((resident) => resident.id === id);
    if (index === -1) {
      throw new NotFoundException('Bewohner nicht gefunden');
    }

    const updated: Resident = {
      ...residents[index],
      firstName: payload.firstName ?? residents[index].firstName,
      lastName: payload.lastName ?? residents[index].lastName,
      postalCode: payload.postalCode ?? residents[index].postalCode,
      houseNumber: payload.houseNumber ?? residents[index].houseNumber,
      status: payload.status ?? residents[index].status,
      updatedAt: new Date().toISOString(),
    };

    residents[index] = updated;
    await this.repository.setAll(tenantId, residents);
    return updated;
  }

  async getById(tenantId: string, id: string): Promise<Resident> {
    const residents = await this.repository.getAll(tenantId);
    const resident = residents.find((entry) => entry.id === id);
    if (!resident) {
      throw new NotFoundException('Bewohner nicht gefunden');
    }
    return resident;
  }

  async findTenantForResidentId(residentId: string): Promise<string | undefined> {
    let entries: Array<{ name: string; isDirectory: () => boolean }> = [];
    try {
      entries = await fs.readdir(this.tenantsPath, { withFileTypes: true });
    } catch {
      return undefined;
    }

    for (const entry of entries) {
      if (!entry.isDirectory()) {
        continue;
      }
      const tenantId = entry.name;
      const residentsPath = join(this.tenantsPath, tenantId, 'residents.json');
      try {
        const file = await fs.readFile(residentsPath, 'utf8');
        const residents = JSON.parse(file) as Resident[];
        if (residents.some((resident) => resident.id === residentId)) {
          return tenantId;
        }
      } catch {
        continue;
      }
    }
    return undefined;
  }

  async findByIdentity(
    tenantId: string,
    payload: {
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    },
  ): Promise<Resident | undefined> {
    const residents = await this.repository.getAll(tenantId);
    return residents.find(
      (resident) =>
        this.normalize(resident.firstName) ===
          this.normalize(payload.firstName) &&
        this.normalize(resident.lastName) === this.normalize(payload.lastName) &&
        this.normalize(resident.postalCode) ===
          this.normalize(payload.postalCode) &&
        this.normalize(resident.houseNumber) ===
          this.normalize(payload.houseNumber),
    );
  }

  async findByAddress(
    tenantId: string,
    postalCode: string,
    houseNumber: string,
  ): Promise<Resident | undefined> {
    const residents = await this.repository.getAll(tenantId);
    const normalizedPostal = this.normalize(postalCode);
    const normalizedHouse = this.normalize(houseNumber);
    return residents.find(
      (resident) =>
        this.normalize(resident.postalCode) === normalizedPostal &&
        this.normalize(resident.houseNumber) === normalizedHouse,
    );
  }

  async upsertResident(
    tenantId: string,
    payload: {
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    },
  ): Promise<string> {
    const existing = await this.findByAddress(
      tenantId,
      payload.postalCode,
      payload.houseNumber,
    );
    const resident = existing
      ? await this.update(tenantId, existing.id, payload)
      : await this.create(tenantId, payload);
    return resident.id;
  }

  async bulkUpsert(
    tenantId: string,
    payload: Array<{
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    }>,
  ): Promise<{
    created: Array<{ residentId: string; displayName: string }>;
    updated: Array<{ residentId: string; displayName: string }>;
    errors: Array<{ index: number; message: string }>;
  }> {
    const created: Array<{ residentId: string; displayName: string }> = [];
    const updated: Array<{ residentId: string; displayName: string }> = [];
    const errors: Array<{ index: number; message: string }> = [];

    for (let index = 0; index < payload.length; index += 1) {
      try {
        const entry = this.normalizeResident(payload[index]);
        const existing = await this.findByAddress(
          tenantId,
          entry.postalCode,
          entry.houseNumber,
        );
        const resident = existing
          ? await this.update(tenantId, existing.id, entry)
          : await this.create(tenantId, entry);
        const summary = {
          residentId: resident.id,
          displayName: this.displayName(resident.firstName, resident.lastName),
        };
        if (existing) {
          updated.push(summary);
        } else {
          created.push(summary);
        }
      } catch (error) {
        errors.push({
          index,
          message: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    return { created, updated, errors };
  }

  private normalize(value: string) {
    return value.trim().toUpperCase();
  }

  private normalizeResident(payload: {
    firstName: string;
    lastName: string;
    postalCode: string;
    houseNumber: string;
  }) {
    return {
      firstName: this.requireString(payload.firstName, 'firstName'),
      lastName: this.requireString(payload.lastName, 'lastName'),
      postalCode: this.normalizePostalCode(payload.postalCode),
      houseNumber: this.requireString(payload.houseNumber, 'houseNumber'),
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private normalizePostalCode(value: string | undefined) {
    const trimmed = this.requireString(value, 'postalCode');
    const digits = trimmed.replace(/\D/g, '');
    if (!digits) {
      throw new BadRequestException('postalCode ist erforderlich');
    }
    return digits;
  }

  private displayName(firstName: string, lastName: string) {
    const initial = lastName.trim().charAt(0);
    return `${firstName.trim()} ${initial}.`;
  }

  private normalizeQuery(value: string) {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return undefined;
    }
    return trimmed.toUpperCase();
  }

  private clampLimit(limit: number) {
    if (!Number.isFinite(limit) || limit <= 0) {
      throw new BadRequestException('limit muss eine Zahl sein');
    }
    return Math.min(limit, 200);
  }
}
