import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Patch,
  Query,
  UseGuards,
  Param,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { ContentType } from '../content/content.types';
import { requireTenant } from '../tenant/tenant-auth';
import { PostsService } from './posts.service';
import { PostEntity, PostType } from './posts.types';

type HidePayload = {
  reason?: string;
};

@Controller('api/admin/posts')
@UseGuards(AdminGuard)
export class AdminPostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get('reported')
  async getReportedPosts(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
  ): Promise<PostEntity[]> {
    const tenantId = requireTenant(headers);
    const parsedType = type ? this.parseType(type) : undefined;
    return this.postsService.getAll({
      tenantId,
      type: parsedType,
      includeHidden: true,
      reportedOnly: true,
    });
  }

  @Patch(':id/hide')
  async hidePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: HidePayload,
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    return this.postsService.hidePost(tenantId, id, payload?.reason);
  }

  @Patch(':id/unhide')
  async unhidePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    return this.postsService.unhidePost(tenantId, id);
  }

  @Patch(':id/reset-reports')
  async resetReports(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    return this.postsService.resetReports(tenantId, id);
  }

  private parseType(value: string): PostType {
    const normalized = value.trim().toUpperCase();
    const aliases: Record<string, ContentType> = {
      EVENT: ContentType.OFFICIAL_EVENT,
      NEWS: ContentType.OFFICIAL_NEWS,
      WARNING: ContentType.OFFICIAL_WARNING,
      MARKET: ContentType.MARKETPLACE_LISTING,
      MARKETPLACE: ContentType.MARKETPLACE_LISTING,
      HELP: ContentType.HELP_REQUEST,
      HELP_REQUEST: ContentType.HELP_REQUEST,
      HELP_OFFER: ContentType.HELP_OFFER,
      CAFE: ContentType.CAFE_MEETUP,
      CAFE_MEETUP: ContentType.CAFE_MEETUP,
      KIDS: ContentType.KIDS_MEETUP,
      KIDS_MEETUP: ContentType.KIDS_MEETUP,
      MOVING: ContentType.MOVING_CLEARANCE,
      MOVING_CLEARANCE: ContentType.MOVING_CLEARANCE,
      APARTMENT: ContentType.APARTMENT_SEARCH,
      APARTMENT_SEARCH: ContentType.APARTMENT_SEARCH,
      LOST_FOUND: ContentType.LOST_FOUND,
      LOST: ContentType.LOST_FOUND,
      RIDE_SHARING: ContentType.RIDE_SHARING,
      JOBS_LOCAL: ContentType.JOBS_LOCAL,
      VOLUNTEERING: ContentType.VOLUNTEERING,
      GIVEAWAY: ContentType.GIVEAWAY,
      SKILL_EXCHANGE: ContentType.SKILL_EXCHANGE,
      USER_POST: ContentType.USER_POST,
    };
    const mapped = aliases[normalized];
    if (!mapped) {
      throw new BadRequestException('type ist ungültig');
    }
    return mapped;
  }
}
