export type ResidentStatus = 'ACTIVE' | 'INACTIVE';

export type Resident = {
  id: string;
  tenantId: string;
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
  status: ResidentStatus;
  createdAt: string;
  updatedAt: string;
};
