import { Injectable } from '@nestjs/common';
import { resolveTenantId } from '../tenant/tenant-resolver';

const ADMIN_KEY_HEADER = 'x-admin-key';

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

const parseAdminKeyMap = () => {
  const raw = process.env.ADMIN_KEYS_JSON;
  if (!raw) {
    return {};
  }

  try {
    const parsed = JSON.parse(raw) as Record<string, string>;
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed
      : {};
  } catch {
    return {};
  }
};

@Injectable()
export class PermissionsService {
  isAdmin(
    headers: Record<string, string | string[] | undefined>,
  ): boolean {
    const adminKey = getHeaderValue(headers, ADMIN_KEY_HEADER)?.trim();
    if (!adminKey) {
      return false;
    }

    const adminKeyMap = parseAdminKeyMap();
    if (Object.keys(adminKeyMap).length === 0) {
      return false;
    }

    const mappedTenant = adminKeyMap[adminKey];
    if (!mappedTenant) {
      return false;
    }

    try {
      const tenantId = resolveTenantId(headers, { required: true });
      return tenantId === mappedTenant;
    } catch {
      return false;
    }
  }
}
