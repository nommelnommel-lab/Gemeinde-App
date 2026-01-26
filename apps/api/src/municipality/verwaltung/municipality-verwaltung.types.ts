export type VerwaltungItemKind = 'FORM' | 'LINK';
export type VerwaltungItemStatus = 'PUBLISHED' | 'HIDDEN';

export type VerwaltungItemMetadata = {
  demoSeed?: boolean;
  [key: string]: unknown;
};

export type VerwaltungItem = {
  id: string;
  tenantId: string;
  kind: VerwaltungItemKind;
  category: string;
  title: string;
  description?: string | null;
  url: string;
  tags: string[];
  status: VerwaltungItemStatus;
  sortOrder: number;
  metadata?: VerwaltungItemMetadata;
  createdAt: string;
  updatedAt: string;
};

export type VerwaltungItemInput = {
  kind: VerwaltungItemKind;
  category: string;
  title: string;
  description?: string | null;
  url: string;
  tags?: string[];
  status?: VerwaltungItemStatus;
  sortOrder?: number;
  metadata?: VerwaltungItemMetadata;
};

export type VerwaltungItemPatch = {
  kind?: VerwaltungItemKind;
  category?: string;
  title?: string;
  description?: string | null;
  url?: string;
  tags?: string[];
  status?: VerwaltungItemStatus;
  sortOrder?: number;
  metadata?: VerwaltungItemMetadata;
};
