import { Category, ContentType } from '../content/content.types';

export type PostType = ContentType;

export type PostEntity = {
  id: string;
  type: PostType;
  category?: Category;
  authorId?: string;
  title: string;
  body: string;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  createdAt: string;
  updatedAt: string;
};
