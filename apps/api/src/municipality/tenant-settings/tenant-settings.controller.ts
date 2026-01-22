import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Put,
} from '@nestjs/common';
import { requireTenant } from '../../tenant/tenant-auth';
import {
  TenantSettings,
  TenantSettingsPayload,
} from './tenant-settings.types';
import { TenantSettingsService } from './tenant-settings.service';

@Controller('api/tenant')
export class TenantSettingsController {
  constructor(private readonly tenantSettingsService: TenantSettingsService) {}

  @Get('settings')
  @Header('Cache-Control', 'private, max-age=30')
  async getSettings(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ): Promise<TenantSettings> {
    const tenantId = requireTenant(headers);
    return this.tenantSettingsService.getSettings(tenantId);
  }

  @Put('settings')
  @Header('Cache-Control', 'no-store')
  async updateSettings(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: TenantSettingsPayload,
  ): Promise<TenantSettings> {
    const tenantId = requireTenant(headers);
    this.validatePayload(payload);
    return this.tenantSettingsService.upsertSettings(tenantId, payload);
  }

  private validatePayload(payload: TenantSettingsPayload) {
    if (payload.name !== undefined && payload.name.trim().length === 0) {
      throw new BadRequestException('name darf nicht leer sein');
    }

    if (
      payload.contactEmail !== undefined &&
      payload.contactEmail.trim().length === 0
    ) {
      throw new BadRequestException('contactEmail darf nicht leer sein');
    }

    if (
      payload.contactPhone !== undefined &&
      payload.contactPhone.trim().length === 0
    ) {
      throw new BadRequestException('contactPhone darf nicht leer sein');
    }

    if (
      payload.websiteUrl !== undefined &&
      payload.websiteUrl.trim().length === 0
    ) {
      throw new BadRequestException('websiteUrl darf nicht leer sein');
    }

    if (payload.address !== undefined && payload.address.trim().length === 0) {
      throw new BadRequestException('address darf nicht leer sein');
    }
  }
}
