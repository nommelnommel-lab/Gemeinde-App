import { Controller, Get, Header, Headers } from '@nestjs/common';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityEventsService } from '../events/municipality-events.service';
import { MunicipalityPostsService } from '../posts/municipality-posts.service';
import { MunicipalityServicesService } from '../services/municipality-services.service';

@Controller()
export class MunicipalityFeedController {
  constructor(
    private readonly municipalityEventsService: MunicipalityEventsService,
    private readonly municipalityPostsService: MunicipalityPostsService,
    private readonly municipalityServicesService: MunicipalityServicesService,
  ) {}

  @Get('api/feed')
  @Header('Cache-Control', 'private, max-age=30')
  async getFeed(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ) {
    const tenantId = requireTenant(headers);
    const now = new Date();
    const toDate = new Date(now);
    toDate.setDate(toDate.getDate() + 28);
    const postsFrom = new Date(now);
    postsFrom.setDate(postsFrom.getDate() - 28);

    const [events, posts, servicesFeatured] = await Promise.all([
      this.municipalityEventsService.listFeed(tenantId, now, toDate, 50),
      this.municipalityPostsService.listFeed(tenantId, postsFrom, now),
      this.municipalityServicesService.listFeatured(tenantId),
    ]);

    return {
      from: now.toISOString(),
      to: toDate.toISOString(),
      events,
      posts,
      servicesFeatured,
    };
  }
}
