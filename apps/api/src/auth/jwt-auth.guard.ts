import {
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { verifyAccessToken } from './jwt.utils';

export class JwtAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const headers = (request?.headers ?? {}) as Record<
      string,
      string | string[] | undefined
    >;
    const payload = verifyAccessToken(headers);
    if (!payload) {
      throw new UnauthorizedException('Authorization fehlt oder ist ungültig');
    }
    request.user = payload;
    return true;
  }
}
