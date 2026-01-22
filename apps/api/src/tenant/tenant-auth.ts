import {
  BadRequestException,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { resolveTenantId } from './tenant-resolver';

const SITE_KEY_HEADER = 'x-site-key';

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

const parseSiteKeyMap = () => {
  const raw = process.env.SITE_KEYS_JSON;
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as Record<string, string>;
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
};

export const requireTenant = (
  headers: Record<string, string | string[] | undefined>,
) => {
  const siteKey = getHeaderValue(headers, SITE_KEY_HEADER)?.trim();
  if (!siteKey) {
    throw new UnauthorizedException('X-SITE-KEY fehlt oder ist ungültig');
  }

  const siteKeyMap = parseSiteKeyMap();
  if (!siteKeyMap) {
    throw new UnauthorizedException('X-SITE-KEY fehlt oder ist ungültig');
  }

  const mappedTenant = siteKeyMap[siteKey];
  if (!mappedTenant) {
    throw new UnauthorizedException('X-SITE-KEY fehlt oder ist ungültig');
  }

  const tenantId = resolveTenantId(headers, { required: true });
  if (tenantId !== mappedTenant) {
    throw new ForbiddenException('X-TENANT stimmt nicht überein');
  }

  return tenantId;
};

export const requireTenantHeaders = (
  headers: Record<string, string | string[] | undefined>,
) => {
  const tenantId = resolveTenantId(headers, { required: true });
  if (!tenantId) {
    throw new BadRequestException('x-tenant Header ist erforderlich');
  }
  return tenantId;
};
