import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { verifyAccessToken } from '../auth/jwt.utils';
import { UserRole } from '../auth/user-roles';
import { Category, ContentType } from '../content/content.types';
import { PermissionsService } from '../permissions/permissions.service';
import { requireTenant } from '../tenant/tenant-auth';
import { PostsService } from './posts.service';
import { PostEntity, PostStatus, PostType } from './posts.types';

type PostPayload = {
  type?: PostType;
  title?: string;
  body?: string;
  metadata?: Record<string, unknown>;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  status?: PostStatus;
};

@Controller('posts')
export class PostsController {
  constructor(
    private readonly postsService: PostsService,
    private readonly permissionsService: PermissionsService,
  ) {}

  @Get()
  async getPosts(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
    @Query('q') query?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ): Promise<PostEntity[]> {
    const tenantId = requireTenant(headers);
    const parsedType = type ? this.parseType(type) : undefined;
    const parsedLimit = limit ? this.parseLimit(limit) : undefined;
    const parsedOffset = offset ? this.parseOffset(offset) : undefined;
    const user = verifyAccessToken(headers);
    const includeHidden =
      user?.role === UserRole.STAFF || user?.role === UserRole.ADMIN;
    return this.postsService.list(tenantId, {
      type: parsedType,
      limit: parsedLimit,
      offset: parsedOffset,
      query,
      includeHidden,
      viewerUserId: user?.sub,
    });
  }

  @Get(':id')
  async getPost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    const user = verifyAccessToken(headers);
    const includeHidden =
      user?.role === UserRole.STAFF || user?.role === UserRole.ADMIN;
    return this.postsService.getById(tenantId, id, {
      includeHidden,
      viewerUserId: user?.sub,
    });
  }

  @Post()
  @UseGuards(new JwtAuthGuard())
  async createPost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: PostPayload,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    const data = this.validatePayload(payload);
    const authorId = request.user?.sub;
    if (!authorId) {
      throw new ForbiddenException('Authentifizierung erforderlich');
    }
    if (this.isOfficial(data.type)) {
      this.requireStaffOrAdmin(request.user?.role);
    } else {
      this.requireCreatePermission(headers, data.type);
    }
    return this.postsService.create({
      tenantId,
      ...data,
      authorUserId: authorId,
      category: this.categoryForType(data.type),
    });
  }

  @Patch(':id')
  @UseGuards(new JwtAuthGuard())
  async updatePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: PostPayload,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ): Promise<PostEntity> {
    const tenantId = requireTenant(headers);
    const post = await this.postsService.getById(tenantId, id, {
      includeHidden: true,
    });
    this.assertCanEdit(post, request.user);
    const patch = this.validatePatch(payload, post, request.user?.role);
    if (patch.type && !this.isOfficial(patch.type)) {
      this.requireCreatePermission(headers, patch.type);
    }
    return this.postsService.update(tenantId, id, {
      ...patch,
      category: patch.type ? this.categoryForType(patch.type) : post.category,
    });
  }

  @Delete(':id')
  @UseGuards(new JwtAuthGuard())
  async deletePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Req() request: { user?: { sub?: string; role?: UserRole } },
  ) {
    const tenantId = requireTenant(headers);
    const post = await this.postsService.getById(tenantId, id, {
      includeHidden: true,
    });
    this.assertCanEdit(post, request.user);
    const role = request.user?.role;
    const reason =
      role === UserRole.STAFF || role === UserRole.ADMIN
        ? 'hidden_by_staff'
        : 'AUTHOR_DELETE';
    await this.postsService.hide(tenantId, id, reason);
    return { ok: true };
  }

  @Post(':id/report')
  @UseGuards(new JwtAuthGuard())
  async reportPost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Req() request: { user?: { sub?: string } },
  ) {
    const tenantId = requireTenant(headers);
    const reporterUserId = request.user?.sub;
    if (!reporterUserId) {
      throw new ForbiddenException('Authentifizierung erforderlich');
    }
    const { alreadyReported } = await this.postsService.report(
      tenantId,
      id,
      reporterUserId,
    );
    return { ok: true, alreadyReported };
  }

  private validatePayload(payload: PostPayload) {
    const type = this.requireType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const metadata = this.validateMetadata(type, payload.metadata);
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
      metadata,
      location,
      date,
      severity,
      validUntil,
    };
  }

  private validatePatch(
    payload: PostPayload,
    existing: PostEntity,
    role?: UserRole,
  ) {
    const patch: Partial<PostPayload> = {};
    if (payload.type !== undefined) {
      patch.type = this.parseType(payload.type);
    }
    if (payload.title !== undefined) {
      patch.title = this.requireString(payload.title, 'title');
    }
    if (payload.body !== undefined) {
      patch.body = this.requireString(payload.body, 'body');
    }
    if (payload.location !== undefined) {
      patch.location = payload.location?.trim() || undefined;
    }
    if (payload.date !== undefined) {
      patch.date = payload.date?.trim();
    }
    if (payload.validUntil !== undefined) {
      patch.validUntil = payload.validUntil?.trim();
    }
    if (payload.severity !== undefined) {
      this.requireSeverity(payload.severity);
      patch.severity = payload.severity;
    }
    if (payload.status !== undefined) {
      if (role !== UserRole.STAFF && role !== UserRole.ADMIN) {
        throw new ForbiddenException('Keine Berechtigung');
      }
      patch.status = this.parsePostStatus(payload.status);
    }

    const resolvedType = patch.type ?? existing.type;
    const metadataInput =
      payload.metadata !== undefined ? payload.metadata : existing.metadata;
    const mergedMetadata = this.validateMetadata(resolvedType, metadataInput);

    if (resolvedType === ContentType.OFFICIAL_EVENT) {
      const effectiveDate = patch.date ?? existing.date;
      if (!effectiveDate) {
        throw new BadRequestException('date ist erforderlich');
      }
    }

    if (resolvedType === ContentType.OFFICIAL_WARNING) {
      const effectiveSeverity = patch.severity ?? existing.severity;
      if (!effectiveSeverity) {
        throw new BadRequestException('severity ist erforderlich');
      }
    }

    return {
      ...patch,
      metadata: mergedMetadata,
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

  private parsePostStatus(value: string | PostStatus): PostStatus {
    const normalized = value.toString().trim().toUpperCase();
    if (normalized === 'PUBLISHED' || normalized === 'HIDDEN') {
      return normalized as PostStatus;
    }
    throw new BadRequestException('status ist ungültig');
  }

  private requireCreatePermission(
    headers: Record<string, string | string[] | undefined>,
    type: PostType,
  ) {
    const permissions = this.permissionsService.getPermissions(headers);
    const { canCreate } = permissions;
    if (
      type === ContentType.MARKETPLACE_LISTING &&
      canCreate.marketplace
    ) {
      return;
    }
    if (
      (type === ContentType.HELP_REQUEST ||
        type === ContentType.HELP_OFFER) &&
      canCreate.help
    ) {
      return;
    }
    if (type === ContentType.MOVING_CLEARANCE && canCreate.movingClearance) {
      return;
    }
    if (type === ContentType.CAFE_MEETUP && canCreate.cafeMeetup) {
      return;
    }
    if (type === ContentType.KIDS_MEETUP && canCreate.kidsMeetup) {
      return;
    }
    if (type === ContentType.APARTMENT_SEARCH && canCreate.apartmentSearch) {
      return;
    }
    if (type === ContentType.LOST_FOUND && canCreate.lostFound) {
      return;
    }
    if (type === ContentType.RIDE_SHARING && canCreate.rideSharing) {
      return;
    }
    if (type === ContentType.JOBS_LOCAL && canCreate.jobsLocal) {
      return;
    }
    if (type === ContentType.VOLUNTEERING && canCreate.volunteering) {
      return;
    }
    if (type === ContentType.GIVEAWAY && canCreate.giveaway) {
      return;
    }
    if (type === ContentType.SKILL_EXCHANGE && canCreate.skillExchange) {
      return;
    }

    throw new ForbiddenException('Keine Berechtigung');
  }

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }

  private parseOffset(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed < 0) {
      throw new BadRequestException('offset muss eine positive Zahl sein');
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
    if (post.authorUserId && post.authorUserId === user.sub) {
      return;
    }
    throw new ForbiddenException('Keine Berechtigung');
  }

  private validateMetadata(
    type: PostType,
    metadata: Record<string, unknown> | undefined,
  ) {
    if (metadata !== undefined && (typeof metadata !== 'object' || Array.isArray(metadata))) {
      throw new BadRequestException('metadata ist ungültig');
    }
    const resolved = metadata ?? {};

    if (type === ContentType.CAFE_MEETUP || type === ContentType.KIDS_MEETUP) {
      this.requireMetadataDate(resolved, 'dateTime');
      this.requireMetadataString(resolved, 'location');
    }
    if (type === ContentType.LOST_FOUND) {
      this.requireMetadataString(resolved, 'type');
      this.requireMetadataDate(resolved, 'date');
      this.requireMetadataString(resolved, 'location');
    }
    if (type === ContentType.APARTMENT_SEARCH) {
      this.requireMetadataString(resolved, 'type');
      this.requireMetadataString(resolved, 'contact');
    }

    return resolved;
  }

  private requireMetadataString(
    metadata: Record<string, unknown>,
    key: string,
  ) {
    const value = metadata[key];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new BadRequestException(`${key} ist erforderlich`);
    }
    return value.trim();
  }

  private requireMetadataDate(
    metadata: Record<string, unknown>,
    key: string,
  ) {
    const value = this.requireMetadataString(metadata, key);
    if (Number.isNaN(Date.parse(value))) {
      throw new BadRequestException(`${key} muss ein gültiger ISO-8601-String sein`);
    }
    return value;
  }
}
