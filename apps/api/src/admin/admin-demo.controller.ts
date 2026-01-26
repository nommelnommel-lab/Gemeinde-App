import {
  Controller,
  ForbiddenException,
  Headers,
  Post,
  UseGuards,
} from '@nestjs/common';
import { MunicipalityPostsService } from '../municipality/posts/municipality-posts.service';
import { resolveTenantId } from '../tenant/tenant-resolver';
import { TourismService } from '../tourism/tourism.service';
import { tourismSeedItems } from '../tourism/tourism-seed-hilders.data';
import { AdminGuard } from './admin.guard';

const DEMO_TENANT = 'hilders-demo';

@Controller('api/admin/demo')
@UseGuards(AdminGuard)
export class AdminDemoController {
  constructor(
    private readonly municipalityPostsService: MunicipalityPostsService,
    private readonly tourismService: TourismService,
  ) {}

  @Post('reset')
  async resetDemo(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ): Promise<{ status: 'ok'; tenant: string }> {
    const tenantId = resolveTenantId(headers, { required: true });
    if (tenantId !== DEMO_TENANT) {
      throw new ForbiddenException('Demo-Reset ist nur für hilders-demo erlaubt');
    }

    await this.municipalityPostsService.resetToSeed(tenantId);
    await this.tourismService.seedDemo(tenantId, tourismSeedItems);

    return { status: 'ok', tenant: tenantId };
  }
}
