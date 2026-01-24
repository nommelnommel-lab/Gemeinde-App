export enum UserRole {
  USER = 'USER',
  STAFF = 'STAFF',
  ADMIN = 'ADMIN',
}

const ROLE_VALUES = new Set<string>(Object.values(UserRole));

export const isUserRole = (value?: string | null): value is UserRole => {
  if (!value) {
    return false;
  }
  return ROLE_VALUES.has(value.trim().toUpperCase());
};

export const normalizeUserRole = (value?: string | null): UserRole => {
  if (!value) {
    return UserRole.USER;
  }
  const normalized = value.trim().toUpperCase();
  return ROLE_VALUES.has(normalized)
    ? (normalized as UserRole)
    : UserRole.USER;
};
