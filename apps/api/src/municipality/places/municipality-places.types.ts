export type PlaceStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type MunicipalityPlace = {
  id: string;
  tenantId: string;
  name: string;
  description: string;
  type: string;
  address?: string;
  lat?: number;
  lon?: number;
  status: PlaceStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityPlaceInput = {
  name: string;
  description: string;
  type: string;
  address?: string;
  lat?: number;
  lon?: number;
  status?: PlaceStatus;
};

export type MunicipalityPlacePatch = {
  name?: string;
  description?: string;
  type?: string;
  address?: string;
  lat?: number;
  lon?: number;
  status?: PlaceStatus;
};
