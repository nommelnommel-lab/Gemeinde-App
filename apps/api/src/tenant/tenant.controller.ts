import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  Put,
  UnauthorizedException,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { TenantConfigService } from './tenant.service';
import { TenantConfigDto } from './dto/tenant-config.dto';
import { resolveTenantId } from './tenant-resolver';
import { TenantConfig } from './tenant.types';

/**
 * curl -H "X-Tenant: demo" http://localhost:3000/tenant/config
 * curl -X PUT -H "X-Tenant: demo" -H "x-admin-key: $ADMIN_KEY" \
 *   -H "Content-Type: application/json" \
 *   --data @payload.json http://localhost:3000/tenant/config
 */
@Controller('tenant')
export class TenantConfigController {
  constructor(private readonly tenantService: TenantConfigService) {}

  @Get('config')
  async getConfig(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ): Promise<TenantConfig> {
    const tenantId = resolveTenantId(headers);
    return this.tenantService.getConfig(tenantId);
  }

  @Put('config')
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  )
  async updateConfig(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: TenantConfigDto,
  ): Promise<TenantConfig> {
    this.requireAdmin(headers);
    const tenantId = resolveTenantId(headers);
    return this.tenantService.updateConfig(tenantId, payload);
  }

  @Get('id')
  async getTenantId(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ) {
    return { tenantId: resolveTenantId(headers) };
  }

  private requireAdmin(
    headers: Record<string, string | string[] | undefined>,
  ) {
    const adminKey = process.env.ADMIN_KEY;
    if (!adminKey) {
      throw new ForbiddenException('Admin-Schlüssel ist erforderlich');
    }

    const providedHeader = headers['x-admin-key'];
    const provided = Array.isArray(providedHeader)
      ? providedHeader[0]
      : providedHeader;

    if (!provided) {
      throw new UnauthorizedException('Admin-Schlüssel fehlt');
    }

    if (provided !== adminKey) {
      throw new ForbiddenException('Ungültiger Admin-Schlüssel');
    }
  }
}
