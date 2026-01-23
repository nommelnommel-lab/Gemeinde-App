import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { Resident, ResidentStatus } from './auth.types';

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

  private normalize(value: string) {
    return value.trim().toUpperCase();
  }
}
