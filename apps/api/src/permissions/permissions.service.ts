import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { resolveTenantId } from '../tenant/tenant-resolver';
import { AccessTokenService } from '../auth/access-token.service';
import { Role, normalizeRole } from '../auth/roles';
import { UsersService } from '../auth/users.service';

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
  constructor(
    private readonly accessTokenService: AccessTokenService,
    private readonly usersService: UsersService,
  ) {}

  async getPermissions(
    headers: Record<string, string | string[] | undefined>,
  ) {
    const role = await this.resolveRole(headers);
    return this.buildPermissions(role);
  }

  private buildPermissions(role: Role) {
    const isAdmin = role === Role.ADMIN;
    const canManageContent = role !== Role.USER;
    return {
      role,
      isAdmin,
      canCreateEvents: canManageContent,
      canCreatePosts: canManageContent,
      canCreateNews: canManageContent,
      canCreateWarnings: canManageContent,
      canModerate: canManageContent,
      canManageResidents: isAdmin,
      canGenerateActivationCodes: isAdmin,
    };
  }

  private async resolveRole(
    headers: Record<string, string | string[] | undefined>,
  ): Promise<Role> {
    const tenantId = resolveTenantId(headers, { required: true });
    const payload = this.accessTokenService.getPayloadFromHeaders(headers);
    if (payload) {
      if (payload.tenantId !== tenantId) {
        throw new ForbiddenException('Token gehört zu einem anderen Tenant');
      }
      try {
        const user = await this.usersService.getById(tenantId, payload.sub);
        return normalizeRole(user.role);
      } catch {
        throw new UnauthorizedException('Benutzer nicht gefunden');
      }
    }

    if (this.hasAdminKey(headers, tenantId)) {
      return Role.ADMIN;
    }

    return Role.USER;
  }

  private hasAdminKey(
    headers: Record<string, string | string[] | undefined>,
    tenantId: string,
  ) {
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

    return tenantId === mappedTenant;
  }
}
