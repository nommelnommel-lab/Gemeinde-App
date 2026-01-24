export enum Role {
  USER = 'USER',
  STAFF = 'STAFF',
  ADMIN = 'ADMIN',
}

const ROLE_RANK: Record<Role, number> = {
  [Role.USER]: 0,
  [Role.STAFF]: 1,
  [Role.ADMIN]: 2,
};

export const normalizeRole = (value?: string | Role | null): Role => {
  if (!value) {
    return Role.USER;
  }
  const normalized = String(value).toUpperCase();
  if (normalized === Role.STAFF) {
    return Role.STAFF;
  }
  if (normalized === Role.ADMIN) {
    return Role.ADMIN;
  }
  return Role.USER;
};

export const hasRequiredRole = (role: Role, required: Role[]): boolean => {
  if (required.length === 0) {
    return true;
  }
  const userRank = ROLE_RANK[role] ?? 0;
  return required.some((requiredRole) => userRank >= ROLE_RANK[requiredRole]);
};
