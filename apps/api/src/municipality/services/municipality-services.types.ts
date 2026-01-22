export type ServiceStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type MunicipalityService = {
  id: string;
  tenantId: string;
  name: string;
  description: string;
  category?: string;
  url?: string;
  featured: boolean;
  status: ServiceStatus;
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityServiceInput = {
  name: string;
  description: string;
  category?: string;
  url?: string;
  featured?: boolean;
  status?: ServiceStatus;
};

export type MunicipalityServicePatch = {
  name?: string;
  description?: string;
  category?: string;
  url?: string;
  featured?: boolean;
  status?: ServiceStatus;
};
