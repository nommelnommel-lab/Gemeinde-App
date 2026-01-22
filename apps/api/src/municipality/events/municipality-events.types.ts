export type EventStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type MunicipalityEvent = {
  id: string;
  tenantId: string;
  title: string;
  description: string;
  location: string;
  startAt: string;
  endAt?: string;
  status: EventStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityEventInput = {
  title: string;
  description: string;
  location: string;
  startAt: string;
  endAt?: string;
  status?: EventStatus;
};

export type MunicipalityEventPatch = {
  title?: string;
  description?: string;
  location?: string;
  startAt?: string;
  endAt?: string;
  status?: EventStatus;
};
