import { Role } from './roles';

export type AuthUser = {
  id: string;
  tenantId: string;
  residentId: string;
  email: string;
  passwordHash: string;
  role: Role;
  emailVerifiedAt?: string;
  createdAt: string;
  updatedAt: string;
};
