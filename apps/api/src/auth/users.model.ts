import { UserRole } from './user-roles';

export type AuthUser = {
  id: string;
  tenantId: string;
  residentId: string;
  email: string;
  passwordHash: string;
  role: UserRole;
  emailVerifiedAt?: string;
  createdAt: string;
  updatedAt: string;
};
