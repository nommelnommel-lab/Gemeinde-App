import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { ROLES_KEY } from './roles.decorator';
import { UserRole } from './user-roles';

type RequestWithUser = {
  user?: {
    role?: UserRole;
  };
};

export class RolesGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const roles =
      (Reflect.getMetadata(ROLES_KEY, context.getHandler()) as UserRole[]) ??
      (Reflect.getMetadata(ROLES_KEY, context.getClass()) as UserRole[]) ??
      [];
    if (!roles || roles.length === 0) {
      return true;
    }
    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const role = request.user?.role;
    if (!role) {
      throw new UnauthorizedException('Keine Rolle gefunden');
    }
    if (!roles.includes(role)) {
      throw new ForbiddenException('Keine Berechtigung');
    }
    return true;
  }
}
