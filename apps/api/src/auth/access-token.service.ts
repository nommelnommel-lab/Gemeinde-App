import { Injectable, UnauthorizedException } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { JwtAccessPayload } from './auth.types';

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

@Injectable()
export class AccessTokenService {
  getPayloadFromHeaders(
    headers: Record<string, string | string[] | undefined>,
    options: { required?: boolean } = {},
  ): JwtAccessPayload | undefined {
    const token = this.getTokenFromHeaders(headers, options);
    if (!token) {
      return undefined;
    }
    return this.verifyToken(token);
  }

  private getTokenFromHeaders(
    headers: Record<string, string | string[] | undefined>,
    options: { required?: boolean },
  ) {
    const authHeader = getHeaderValue(headers, 'authorization');
    if (!authHeader) {
      if (options.required) {
        throw new UnauthorizedException('Authorization fehlt');
      }
      return undefined;
    }

    const [type, token] = authHeader.split(' ');
    if (!token || type.toLowerCase() !== 'bearer') {
      throw new UnauthorizedException('Authorization Header ist ungültig');
    }

    return token.trim();
  }

  private verifyToken(token: string): JwtAccessPayload {
    try {
      const payload = jwt.verify(token, this.jwtSecret());
      if (!payload || typeof payload !== 'object') {
        throw new UnauthorizedException('Access token ungültig');
      }
      return payload as JwtAccessPayload;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Access token ungültig');
    }
  }

  private jwtSecret() {
    return process.env.JWT_SECRET || 'dev-secret-change-me';
  }
}
