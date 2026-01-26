import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { AuthUser } from './users.model';
import { normalizeUserRole, UserRole } from './user-roles';

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
    return this.normalizeUser(user);
  }

  async getById(tenantId: string, id: string): Promise<AuthUser> {
    const users = await this.repository.getAll(tenantId);
    const user = users.find((entry) => entry.id === id);
    if (!user) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }
    return this.normalizeUser(user);
  }

  async list(
    tenantId: string,
    query?: string,
  ): Promise<AuthUser[]> {
    const users = await this.repository.getAll(tenantId);
    if (!query) {
      return [...users].sort(
        (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
      );
    }
    const normalized = this.normalizeText(query);
    return users
      .filter((entry) => {
        const email = this.normalizeText(entry.email ?? '');
        return email.includes(normalized) || entry.id.includes(query);
      })
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
  }

  async findByEmail(tenantId: string, email: string): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    const normalized = this.normalizeText(email);
    const match = users.find(
      (entry) => this.normalizeText(entry.email) === normalized,
    );
    return match ? this.normalizeUser(match) : undefined;
  }

  async findByResidentId(
    tenantId: string,
    residentId: string,
  ): Promise<AuthUser | undefined> {
    const users = await this.repository.getAll(tenantId);
    const match = users.find((entry) => entry.residentId === residentId);
    return match ? this.normalizeUser(match) : undefined;
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
    return this.normalizeUser(updated);
  }

  private normalizeText(value: string): string {
    return value
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '');
  }

  private normalizeUser(user: AuthUser): AuthUser {
    return { ...user, role: normalizeRole(user.role) };
  }

  private normalizePatch(patch: Partial<AuthUser>): Partial<AuthUser> {
    if (patch.role === undefined) {
      return patch;
    }
    return { ...patch, role: normalizeRole(patch.role) };
  }
}

const normalizeRole = (value?: string | null): UserRole => {
  return normalizeUserRole(value);
};
