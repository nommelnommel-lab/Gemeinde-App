import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { resolveTenantId } from '../tenant/tenant-resolver';
import { AccessTokenService } from './access-token.service';
import { UsersService } from './users.service';
import { ROLES_KEY } from './roles.decorator';
import { Role, hasRequiredRole, normalizeRole } from './roles';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly accessTokenService: AccessTokenService,
    private readonly usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const requiredRoles =
      this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) ?? [];

    if (requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const headers = (request?.headers ?? {}) as Record<
      string,
      string | string[] | undefined
    >;

    const payload = this.accessTokenService.getPayloadFromHeaders(headers, {
      required: true,
    });

    if (!payload?.sub || !payload.tenantId) {
      throw new UnauthorizedException('Access token ungültig');
    }

    const tenantId = resolveTenantId(headers, { required: true });
    if (payload.tenantId !== tenantId) {
      throw new ForbiddenException('Token gehört zu einem anderen Tenant');
    }

    let userRole = Role.USER;
    try {
      const user = await this.usersService.getById(tenantId, payload.sub);
      userRole = normalizeRole(user.role);
    } catch {
      throw new UnauthorizedException('Benutzer nicht gefunden');
    }

    if (!hasRequiredRole(userRole, requiredRoles)) {
      throw new ForbiddenException('Keine Berechtigung für diese Aktion');
    }

    return true;
  }
}
