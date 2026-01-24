import {
  Body,
  Controller,
  Get,
  Headers,
  Put,
  UsePipes,
  ValidationPipe,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/user-roles';
import { TenantConfigService } from './tenant.service';
import { TenantConfigDto } from './dto/tenant-config.dto';
import { resolveTenantId } from './tenant-resolver';
import { TenantConfig } from './tenant.types';

/**
 * curl -H "X-Tenant: demo" http://localhost:3000/tenant/config
 * curl -X PUT -H "X-Tenant: demo" -H "Authorization: Bearer <token>" \
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
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
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
    const tenantId = resolveTenantId(headers);
    return this.tenantService.updateConfig(tenantId, payload);
  }

  @Get('id')
  async getTenantId(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ) {
    return { tenantId: resolveTenantId(headers) };
  }

}
