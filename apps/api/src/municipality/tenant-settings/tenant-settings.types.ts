export type TenantSettings = {
  tenantId: string;
  name: string;
  contactEmail?: string;
  contactPhone?: string;
  websiteUrl?: string;
  address?: string;
  openingHoursJson: Record<string, unknown> | unknown[];
  brandingJson: Record<string, unknown> | unknown[];
  featureFlagsJson: Record<string, unknown> | unknown[];
  createdAt: string;
  updatedAt: string;
};

export type TenantSettingsPayload = {
  name?: string;
  contactEmail?: string;
  contactPhone?: string;
  websiteUrl?: string;
  address?: string;
  openingHoursJson?: Record<string, unknown> | unknown[];
  brandingJson?: Record<string, unknown> | unknown[];
  featureFlagsJson?: Record<string, unknown> | unknown[];
};
