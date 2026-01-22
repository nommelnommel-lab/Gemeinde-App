export type ClubStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type MunicipalityClub = {
  id: string;
  tenantId: string;
  name: string;
  description: string;
  contactName?: string;
  email?: string;
  phone?: string;
  website?: string;
  status: ClubStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityClubInput = {
  name: string;
  description: string;
  contactName?: string;
  email?: string;
  phone?: string;
  website?: string;
  status?: ClubStatus;
};

export type MunicipalityClubPatch = {
  name?: string;
  description?: string;
  contactName?: string;
  email?: string;
  phone?: string;
  website?: string;
  status?: ClubStatus;
};
