import { BadRequestException } from '@nestjs/common';

const TENANT_HEADER = 'x-tenant';
const DEFAULT_TENANT = 'demo';
const TENANT_PATTERN = /^[a-z0-9-]+$/;
const MAX_TENANT_LENGTH = 40;

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

export const resolveTenantId = (
  headers: Record<string, string | string[] | undefined>,
  options: { required?: boolean } = {},
) => {
  const rawValue = getHeaderValue(headers, TENANT_HEADER);
  const fallback = options.required ? undefined : DEFAULT_TENANT;
  const tenantId = rawValue?.trim() || fallback;

  if (!tenantId) {
    throw new BadRequestException('X-TENANT fehlt');
  }

  const normalized = tenantId.toLowerCase();
  if (normalized.length > MAX_TENANT_LENGTH) {
    throw new BadRequestException('tenantId ist zu lang');
  }

  if (!TENANT_PATTERN.test(normalized)) {
    throw new BadRequestException(
      'tenantId darf nur Kleinbuchstaben, Zahlen und Bindestriche enthalten',
    );
  }

  return normalized;
};
