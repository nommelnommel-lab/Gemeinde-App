export enum TouristAccessCodeStatus {
  ACTIVE = 'ACTIVE',
  REDEEMED = 'REDEEMED',
  REVOKED = 'REVOKED',
}

export type TouristAccessCode = {
  id: string;
  tenantId: string;
  codeHash: string;
  durationDays: 7 | 14 | 30;
  status: TouristAccessCodeStatus;
  redeemedAt?: string | null;
  redeemedByDeviceId?: string | null;
  createdAt: string;
};
