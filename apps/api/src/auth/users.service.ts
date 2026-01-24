import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { AuthUser } from './users.model';
import { UserRole } from './user-roles';

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
      role?: UserRole;
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
      role: payload.role ?? UserRole.USER,
      emailVerifiedAt: payload.emailVerifiedAt,
      createdAt: now,
      updatedAt: now,
    };
    users.push(user);
    await this.repository.setAll(tenantId, users);
    return this.normalize(user);
  }

  async getById(tenantId: string, id: string): Promise<AuthUser> {
    const users = await this.repository.getAll(tenantId);
    const user = users.find((entry) => entry.id === id);
    if (!user) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }
    return this.normalize(user);
  }

  async list(
    tenantId: string,
    query?: string,
  ): Promise<AuthUser[]> {
    const users = await this.repository.getAll(tenantId);
    if (!query) {
      return users;
    }
    const normalized = this.normalize(query);
    return users.filter((entry) => {
      const email = this.normalize(entry.email);
      return email.includes(normalized) || entry.id.includes(query);
    });
  }

  async findByEmail(tenantId: string, email: string): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    const normalized = this.normalizeString(email);
    const match = users.find(
      (entry) => this.normalizeString(entry.email) === normalized,
    );
    return match ? this.normalize(match) : undefined;
  }

  async findByResidentId(
    tenantId: string,
    residentId: string,
  ): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    const match = users.find((entry) => entry.residentId === residentId);
    return match ? this.normalize(match) : undefined;
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
      ...this.normalizePatch(patch),
      updatedAt: new Date().toISOString(),
    };
    users[index] = updated;
    await this.repository.setAll(tenantId, users);
    return this.normalize(updated);
  }

  private normalizeString(value: string) {
    return value.trim().toLowerCase();
  }

  private normalize(user: AuthUser): AuthUser {
    return { ...user, role: normalizeRole(user.role) };
  }

  private normalizePatch(patch: Partial<AuthUser>): Partial<AuthUser> {
    if (patch.role === undefined) {
      return patch;
    }
    return { ...patch, role: normalizeRole(patch.role) };
  }
}
