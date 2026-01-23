export type ResidentStatus = 'ACTIVE' | 'MOVED' | 'INACTIVE';

export type Resident = {
  id: string;
  tenantId: string;
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
  status: ResidentStatus;
  createdAt: string;
  updatedAt: string;
};

export type ActivationCode = {
  id: string;
  tenantId: string;
  residentId: string;
  codeHash: string;
  expiresAt: string;
  usedAt?: string;
  revokedAt?: string;
  attemptCount: number;
  lastAttemptAt?: string;
  createdAt: string;
};

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

export type RefreshToken = {
  id: string;
  tenantId: string;
  userId: string;
  tokenHash: string;
  expiresAt: string;
  revokedAt?: string;
  createdAt: string;
};
