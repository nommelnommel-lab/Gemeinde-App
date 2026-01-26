export type TourismItemType =
  | 'HIKING_ROUTE'
  | 'SIGHT'
  | 'LEISURE'
  | 'RESTAURANT';

export type TourismItemStatus = 'PUBLISHED' | 'HIDDEN';

export type TourismItemEntity = {
  id: string;
  tenantId: string;
  type: TourismItemType;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
  status: TourismItemStatus;
  createdAt: string;
  updatedAt: string;
};
