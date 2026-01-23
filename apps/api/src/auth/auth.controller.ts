import {
  Body,
  Controller,
  Headers,
  Post,
  Req,
} from '@nestjs/common';
import { requireTenant } from '../tenant/tenant-auth';
import { AuthService } from './auth.service';
import { ActivateDto } from './dto/activate.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { AuthResponse } from './auth.types';

@Controller()
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('api/auth/activate')
  async activate(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ActivateDto,
    @Req()
    request: { ip?: string; socket?: { remoteAddress?: string } },
  ): Promise<AuthResponse> {
    const tenantId = requireTenant(headers);
    const clientKey = this.getClientKey(request, headers);
    return this.authService.activate(tenantId, payload, clientKey);
  }

  @Post('api/auth/login')
  async login(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: LoginDto,
    @Req()
    request: { ip?: string; socket?: { remoteAddress?: string } },
  ): Promise<AuthResponse> {
    const tenantId = requireTenant(headers);
    const clientKey = this.getClientKey(request, headers);
    return this.authService.login(tenantId, payload, clientKey);
  }

  @Post('api/auth/refresh')
  async refresh(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: RefreshDto,
  ): Promise<AuthResponse> {
    const tenantId = requireTenant(headers);
    return this.authService.refresh(tenantId, payload);
  }

  @Post('api/auth/logout')
  async logout(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: RefreshDto,
  ) {
    const tenantId = requireTenant(headers);
    return this.authService.logout(tenantId, payload);
  }

  private getClientKey(
    request: { ip?: string; socket?: { remoteAddress?: string } },
    headers: Record<string, string | string[] | undefined>,
  ) {
    const forwarded = this.getHeaderValue(headers, 'x-forwarded-for');
    if (forwarded) {
      return forwarded.split(',')[0]?.trim();
    }

    const ip = request.ip || request.socket?.remoteAddress;
    return ip || 'unknown';
  }

  private getHeaderValue(
    headers: Record<string, string | string[] | undefined>,
    headerName: string,
  ) {
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
  }
}
