export type PostStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
export type PostType = 'NEWS' | 'WARNING';
export type PostPriority = 'HIGH' | 'MEDIUM' | 'LOW';

export type MunicipalityPost = {
  id: string;
  tenantId: string;
  type: PostType;
  title: string;
  body: string;
  priority?: PostPriority;
  publishedAt: string;
  endsAt?: string;
  status: PostStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityPostInput = {
  type: PostType;
  title: string;
  body: string;
  priority?: PostPriority;
  publishedAt: string;
  endsAt?: string;
  status?: PostStatus;
};

export type MunicipalityPostPatch = {
  type?: PostType;
  title?: string;
  body?: string;
  priority?: PostPriority;
  publishedAt?: string;
  endsAt?: string;
  status?: PostStatus;
};
