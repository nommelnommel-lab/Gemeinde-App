export type WarningSeverity = 'info' | 'minor' | 'major' | 'critical';

export interface WarningEntity {
  id: string;
  title: string;
  description: string;
  severity: WarningSeverity;
  publishedAt: string;
  validUntil: string | null;
  createdAt: string;
  updatedAt: string;
}
