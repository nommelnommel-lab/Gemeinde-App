import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { AuthUser } from './users.model';

@Injectable()
export class UsersService {
  private readonly repository = new TenantFileRepository<AuthUser>('users');

  async create(
    tenantId: string,
    payload: {
      residentId: string;
      email: string;
      passwordHash: string;
      emailVerifiedAt?: string;
    },
  ): Promise<AuthUser> {
    const users = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const user: AuthUser = {
      id: randomUUID(),
      tenantId,
      residentId: payload.residentId,
      email: payload.email,
      passwordHash: payload.passwordHash,
      emailVerifiedAt: payload.emailVerifiedAt,
      createdAt: now,
      updatedAt: now,
    };
    users.push(user);
    await this.repository.setAll(tenantId, users);
    return user;
  }

  async getById(tenantId: string, id: string): Promise<AuthUser> {
    const users = await this.repository.getAll(tenantId);
    const user = users.find((entry) => entry.id === id);
    if (!user) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }
    return user;
  }

  async findByEmail(tenantId: string, email: string): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    const normalized = this.normalize(email);
    return users.find((entry) => this.normalize(entry.email) === normalized);
  }

  async findByResidentId(
    tenantId: string,
    residentId: string,
  ): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    return users.find((entry) => entry.residentId === residentId);
  }

  async update(
    tenantId: string,
    id: string,
    patch: Partial<AuthUser>,
  ): Promise<AuthUser> {
    const users = await this.repository.getAll(tenantId);
    const index = users.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }

    const updated: AuthUser = {
      ...users[index],
      ...patch,
      updatedAt: new Date().toISOString(),
    };
    users[index] = updated;
    await this.repository.setAll(tenantId, users);
    return updated;
  }

  private normalize(value: string) {
    return value.trim().toLowerCase();
  }
}
