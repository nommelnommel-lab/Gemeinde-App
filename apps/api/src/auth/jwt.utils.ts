import * as jwt from 'jsonwebtoken';
import { JwtAccessPayload } from './auth.types';
import { normalizeUserRole } from './user-roles';

const AUTH_HEADER = 'authorization';

const getHeaderValue = (
  headers: Record<string, string | string[] | undefined>,
  headerName: string,
) => {
  const direct = headers[headerName];
  const resolved =
    direct ??
    Object.entries(headers).find(
      ([key]) => key.toLowerCase() === headerName.toLowerCase(),
    )?.[1];

  if (Array.isArray(resolved)) {
    return resolved[0];
  }

  return resolved;
};

export const getJwtSecret = () => {
  return process.env.JWT_SECRET || 'dev-secret-change-me';
};

export const extractBearerToken = (
  headers: Record<string, string | string[] | undefined>,
) => {
  const raw = getHeaderValue(headers, AUTH_HEADER);
  if (!raw) {
    return undefined;
  }
  const [scheme, token] = raw.trim().split(/\s+/);
  if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) {
    return undefined;
  }
  return token;
};

export const verifyAccessToken = (
  headers: Record<string, string | string[] | undefined>,
): JwtAccessPayload | null => {
  const token = extractBearerToken(headers);
  if (!token) {
    return null;
  }
  try {
    const payload = jwt.verify(token, getJwtSecret()) as JwtAccessPayload;
    if (payload.expiresAt) {
      const expiresAt = Date.parse(payload.expiresAt);
      if (!Number.isNaN(expiresAt) && expiresAt <= Date.now()) {
        return null;
      }
    }
    return {
      ...payload,
      role: normalizeUserRole(payload.role),
    };
  } catch {
    return null;
  }
};
