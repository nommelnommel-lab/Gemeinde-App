export type AuthUser = {
  id: string;
  tenantId: string;
  residentId: string;
  email: string;
  passwordHash: string;
  emailVerifiedAt?: string;
  createdAt: string;
  updatedAt: string;
};
