export type RefreshToken = {
  id: string;
  tenantId: string;
  userId: string;
  tokenHash: string;
  expiresAt: string;
  createdAt: string;
  revokedAt?: string;
};
