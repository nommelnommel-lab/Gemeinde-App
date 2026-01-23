export type ActivationCode = {
  id: string;
  tenantId: string;
  residentId: string;
  codeHash: string;
  expiresAt: string;
  attemptCount: number;
  createdAt: string;
  usedAt?: string;
  revokedAt?: string;
};
