import { Category, ContentType } from '../content/content.types';

export type PostType = ContentType;

export type PostEntity = {
  id: string;
  tenantId: string;
  type: PostType;
  category?: Category;
  authorId?: string;
  title: string;
  body: string;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  status: 'PUBLISHED' | 'HIDDEN';
  reportsCount: number;
  reportedAt?: string;
  hiddenReason?: string;
  createdAt: string;
  updatedAt: string;
};
