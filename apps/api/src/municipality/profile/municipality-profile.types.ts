export type MunicipalityProfileAddress = {
  street: string;
  zip: string;
  city: string;
};

export type MunicipalityProfileOpeningSlot = {
  from: string;
  to: string;
};

export type MunicipalityProfileOpeningHour = {
  weekday: string;
  slots: MunicipalityProfileOpeningSlot[];
  note?: string;
};

export type MunicipalityProfileLink = {
  label: string;
  url: string;
};

export type MunicipalityProfileEmergencyNumber = {
  label: string;
  number: string;
};

export type MunicipalityProfile = {
  tenantId: string;
  name: string;
  address: MunicipalityProfileAddress;
  phone: string;
  fax: string;
  email: string;
  websiteUrl: string;
  openingHours: MunicipalityProfileOpeningHour[];
  importantLinks: MunicipalityProfileLink[];
  emergencyNumbers: MunicipalityProfileEmergencyNumber[];
  createdAt: string;
  updatedAt: string;
};

export type MunicipalityProfilePayload = Omit<
  MunicipalityProfile,
  'tenantId' | 'createdAt' | 'updatedAt'
>;
