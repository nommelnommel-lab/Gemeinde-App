import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { Resident, ResidentStatus } from './residents.model';

@Injectable()
export class ResidentsService {
  private readonly repository = new TenantFileRepository<Resident>('residents');

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
      postalCode: this.requireString(payload.postalCode, 'postalCode'),
      houseNumber: this.requireString(payload.houseNumber, 'houseNumber'),
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new Error(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private displayName(firstName: string, lastName: string) {
    const initial = lastName.trim().charAt(0);
    return `${firstName.trim()} ${initial}.`;
  }
}
