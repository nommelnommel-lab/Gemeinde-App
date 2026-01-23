import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
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
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as Record<string, string>;
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
};

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest();
    const headers = (request?.headers ?? {}) as Record<
      string,
      string | string[] | undefined
    >;

    const adminKey = getHeaderValue(headers, ADMIN_KEY_HEADER)?.trim();
    if (!adminKey) {
      throw new UnauthorizedException('X-ADMIN-KEY fehlt oder ist ungültig');
    }

    const adminKeyMap = parseAdminKeyMap();
    if (!adminKeyMap) {
      throw new UnauthorizedException('X-ADMIN-KEY fehlt oder ist ungültig');
    }

    const mappedTenant = adminKeyMap[adminKey];
    if (!mappedTenant) {
      throw new UnauthorizedException('X-ADMIN-KEY fehlt oder ist ungültig');
    }

    const tenantId = resolveTenantId(headers, { required: true });
    if (tenantId !== mappedTenant) {
      throw new ForbiddenException('X-ADMIN-KEY stimmt nicht zur Gemeinde');
    }

    return true;
  }
}
