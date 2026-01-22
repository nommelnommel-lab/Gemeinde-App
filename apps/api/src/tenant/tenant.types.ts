export const TENANT_DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as const;

export type TenantDay = (typeof TENANT_DAYS)[number];

export type TenantOpeningHours = {
  day: TenantDay;
  opens?: string;
  closes?: string;
  note?: string;
  closed?: boolean;
};

export type TenantEmergencyNumber = {
  label: string;
  phone: string;
};

export type TenantConfig = {
  tenantId: string;
  name: string;
  contactPhone: string;
  contactEmail: string;
  websiteUrl: string;
  address: string;
  openingHours: TenantOpeningHours[];
  emergencyNumbers: TenantEmergencyNumber[];
  updatedAt: string;
  createdAt: string;
};
