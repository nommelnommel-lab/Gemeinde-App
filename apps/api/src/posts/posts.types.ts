export type PostType =
  | 'event'
  | 'news'
  | 'warning'
  | 'market'
  | 'help'
  | 'cafe'
  | 'kids';

export type PostEntity = {
  id: string;
  type: PostType;
  title: string;
  body: string;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  createdAt: string;
  updatedAt: string;
};
