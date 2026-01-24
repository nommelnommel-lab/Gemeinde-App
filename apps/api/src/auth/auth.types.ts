import { UserRole } from './user-roles';

export type JwtAccessPayload = {
  sub: string;
  tenantId: string;
  residentId: string;
  email: string;
  role: UserRole;
};

export type AuthUserView = {
  id: string;
  tenantId: string;
  residentId: string;
  displayName: string;
  email: string;
  role: UserRole;
};

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: AuthUserView;
};
