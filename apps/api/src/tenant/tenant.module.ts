import { Module } from '@nestjs/common';
import { TenantConfigController } from './tenant.controller';
import { TenantConfigService } from './tenant.service';

@Module({
  controllers: [TenantConfigController],
  providers: [TenantConfigService],
})
export class TenantModule {}
