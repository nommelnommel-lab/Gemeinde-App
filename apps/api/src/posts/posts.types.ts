import { Category, ContentType } from '../content/content.types';

export type PostType = ContentType;

export type PostStatus = 'PUBLISHED' | 'HIDDEN';

export type PostEntity = {
  id: string;
  tenantId: string;
  type: PostType;
  category?: Category;
  authorUserId?: string;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  status: PostStatus;
  reportsCount: number;
  reportedAt?: string;
  hiddenAt?: string;
  hiddenReason?: string;
  createdAt: string;
  updatedAt: string;
};
