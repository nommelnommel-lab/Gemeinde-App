import { Body, Controller, Headers, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { requireTenant } from '../tenant/tenant-auth';
import { AuthService } from './auth.service';

@Controller('api/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('activate')
  async activate(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body()
    payload: {
      activationCode: string;
      email: string;
      password: string;
      postalCode: string;
      houseNumber: string;
    },
    @Req() request: Request,
  ) {
    const tenantId = requireTenant(headers);
    return this.authService.activate(tenantId, payload, this.getIp(request));
  }

  @Post('login')
  async login(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: { email: string; password: string },
    @Req() request: Request,
  ) {
    const tenantId = requireTenant(headers);
    return this.authService.login(tenantId, payload, this.getIp(request));
  }

  @Post('refresh')
  async refresh(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: { refreshToken: string },
  ) {
    const tenantId = requireTenant(headers);
    return this.authService.refresh(tenantId, payload.refreshToken);
  }

  @Post('logout')
  async logout(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: { refreshToken: string },
  ) {
    const tenantId = requireTenant(headers);
    return this.authService.logout(tenantId, payload.refreshToken);
  }

  private getIp(request: Request) {
    const forwarded = request.headers['x-forwarded-for'];
    if (Array.isArray(forwarded)) {
      return forwarded[0];
    }
    if (typeof forwarded === 'string') {
      return forwarded.split(',')[0].trim();
    }
    return request.ip ?? 'unknown';
  }
}
