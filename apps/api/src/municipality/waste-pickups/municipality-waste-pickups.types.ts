export type WastePickupStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type MunicipalityWastePickup = {
  id: string;
  tenantId: string;
  district: string;
  wasteType: string;
  pickupDate: string;
  status: WastePickupStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityWastePickupInput = {
  district: string;
  wasteType: string;
  pickupDate: string;
  status?: WastePickupStatus;
};

export type MunicipalityWastePickupBulkPayload = {
  pickups: MunicipalityWastePickupInput[];
};
