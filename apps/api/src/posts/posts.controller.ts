import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserRole } from '../auth/user-roles';
import { Category, ContentType } from '../content/content.types';
import { PostsService } from './posts.service';
import { PostEntity, PostType } from './posts.types';

type PostPayload = {
  type?: PostType;
  title?: string;
  body?: string;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
};

@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  async getPosts(
    @Query('type') type?: string,
    @Query('limit') limit?: string,
  ): Promise<PostEntity[]> {
    const parsedType = type ? this.parseType(type) : undefined;
    const parsedLimit = limit ? this.parseLimit(limit) : undefined;
    return this.postsService.getAll({ type: parsedType, limit: parsedLimit });
  }

  @Get(':id')
  async getPost(@Param('id') id: string): Promise<PostEntity> {
    return this.postsService.getById(id);
  }

  @Post()
  @UseGuards(new JwtAuthGuard())
  async createPost(
    @Body() payload: PostPayload,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ): Promise<PostEntity> {
    const data = this.validatePayload(payload);
    const authorId = request.user?.sub;
    if (!authorId) {
      throw new ForbiddenException('Authentifizierung erforderlich');
    }
    if (this.isOfficial(data.type)) {
      this.requireStaffOrAdmin(request.user?.role);
    }
    return this.postsService.create({
      ...data,
      authorId,
      category: this.categoryForType(data.type),
    });
  }

  @Patch(':id')
  @UseGuards(new JwtAuthGuard())
  async updatePost(
    @Param('id') id: string,
    @Body() payload: PostPayload,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ): Promise<PostEntity> {
    const data = this.validatePayload(payload);
    const post = await this.postsService.getById(id);
    this.assertCanEdit(post, request.user);
    return this.postsService.update(id, {
      ...data,
      category: this.categoryForType(data.type),
    });
  }

  @Delete(':id')
  @UseGuards(new JwtAuthGuard())
  async deletePost(
    @Param('id') id: string,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ) {
    const post = await this.postsService.getById(id);
    this.assertCanEdit(post, request.user);
    await this.postsService.remove(id);
    return { ok: true };
  }

  private validatePayload(payload: PostPayload) {
    const type = this.requireType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const location = payload.location?.trim() || undefined;
    const date = payload.date?.trim();
    const validUntil = payload.validUntil?.trim();

    if (type === ContentType.OFFICIAL_EVENT) {
      if (!date) {
        throw new BadRequestException('date ist erforderlich');
      }
    }

    if (date && Number.isNaN(Date.parse(date))) {
      throw new BadRequestException('date muss ein gültiger ISO-8601-String sein');
    }

    if (validUntil && Number.isNaN(Date.parse(validUntil))) {
      throw new BadRequestException(
        'validUntil muss ein gültiger ISO-8601-String sein',
      );
    }

    const severity = payload.severity;
    if (type === ContentType.OFFICIAL_WARNING) {
      if (!severity) {
        throw new BadRequestException('severity ist erforderlich');
      }
      this.requireSeverity(severity);
    } else if (severity) {
      this.requireSeverity(severity);
    }

    return {
      type,
      title,
      body,
      location,
      date,
      severity,
      validUntil,
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private requireType(value: PostType | undefined): PostType {
    if (!value) {
      throw new BadRequestException('type ist erforderlich');
    }
    return this.parseType(value);
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

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }

  private requireSeverity(value: string) {
    if (!['low', 'medium', 'high'].includes(value)) {
      throw new BadRequestException('severity ist ungültig');
    }
  }

  private isOfficial(type: PostType) {
    return (
      type === ContentType.OFFICIAL_NEWS ||
      type === ContentType.OFFICIAL_WARNING ||
      type === ContentType.OFFICIAL_EVENT
    );
  }

  private categoryForType(type: PostType): Category | undefined {
    switch (type) {
      case ContentType.MARKETPLACE_LISTING:
        return Category.MARKETPLACE;
      case ContentType.HELP_REQUEST:
        return Category.HELP_REQUEST;
      case ContentType.HELP_OFFER:
        return Category.HELP_OFFER;
      case ContentType.MOVING_CLEARANCE:
        return Category.MOVING_CLEARANCE;
      case ContentType.CAFE_MEETUP:
        return Category.CAFE_MEETUP;
      case ContentType.KIDS_MEETUP:
        return Category.KIDS_MEETUP;
      case ContentType.APARTMENT_SEARCH:
        return Category.APARTMENT_SEARCH;
      case ContentType.LOST_FOUND:
        return Category.LOST_FOUND;
      case ContentType.RIDE_SHARING:
        return Category.RIDE_SHARING;
      case ContentType.JOBS_LOCAL:
        return Category.JOBS_LOCAL;
      case ContentType.VOLUNTEERING:
        return Category.VOLUNTEERING;
      case ContentType.GIVEAWAY:
        return Category.GIVEAWAY;
      case ContentType.SKILL_EXCHANGE:
        return Category.SKILL_EXCHANGE;
      default:
        return undefined;
    }
  }

  private requireStaffOrAdmin(role?: UserRole) {
    if (role === UserRole.STAFF || role === UserRole.ADMIN) {
      return;
    }
    throw new ForbiddenException('Keine Berechtigung');
  }

  private assertCanEdit(
    post: PostEntity,
    user?: { sub?: string; role?: UserRole },
  ) {
    if (!user?.sub) {
      throw new ForbiddenException('Authentifizierung erforderlich');
    }
    if (this.isOfficial(post.type)) {
      this.requireStaffOrAdmin(user.role);
      return;
    }
    if (user.role === UserRole.STAFF || user.role === UserRole.ADMIN) {
      return;
    }
    if (post.authorId && post.authorId === user.sub) {
      return;
    }
    throw new ForbiddenException('Keine Berechtigung');
  }
}
