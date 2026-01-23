export type JwtAccessPayload = {
  sub: string;
  tenantId: string;
  residentId: string;
  email: string;
};

export type AuthUserView = {
  id: string;
  tenantId: string;
  residentId: string;
  displayName: string;
  email: string;
};

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: AuthUserView;
};
