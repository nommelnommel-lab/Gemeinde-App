import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Headers,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityPostsService } from './municipality-posts.service';
import {
  MunicipalityPost,
  MunicipalityPostInput,
  MunicipalityPostPatch,
  PostPriority,
  PostStatus,
  PostType,
} from './municipality-posts.types';

@Controller()
export class MunicipalityPostsController {
  constructor(private readonly municipalityPostsService: MunicipalityPostsService) {}

  @Get('api/posts')
  @Header('Cache-Control', 'private, max-age=30')
  async getPosts(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ): Promise<MunicipalityPost[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityPostsService.list(tenantId, {
      type: type ? this.parseType(type) : undefined,
      from: this.parseDate(from, 'from'),
      to: this.parseDate(to, 'to'),
      status: status ? this.parseStatus(status) : undefined,
      limit: limit ? this.parseLimit(limit) : undefined,
      now: new Date(),
    });
  }

  @Get('api/feed/posts')
  @Header('Cache-Control', 'private, max-age=30')
  async getPostsFeed(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('from') from?: string,
    @Query('days') days?: string,
  ): Promise<MunicipalityPost[]> {
    const tenantId = requireTenant(headers);
    const anchor = this.parseDate(from, 'from') ?? new Date();
    const parsedDays = days ? this.parsePositiveNumber(days, 'days') : 28;
    const fromDate = new Date(anchor);
    fromDate.setDate(anchor.getDate() - parsedDays);
    return this.municipalityPostsService.listFeed(tenantId, fromDate, anchor);
  }

  @Post('api/admin/posts')
  @Header('Cache-Control', 'no-store')
  async createPost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityPostInput,
  ): Promise<MunicipalityPost> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.municipalityPostsService.create(tenantId, input);
  }

  @Patch('api/admin/posts/:id')
  @Header('Cache-Control', 'no-store')
  async updatePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: MunicipalityPostPatch,
  ): Promise<MunicipalityPost> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.municipalityPostsService.update(tenantId, id, patch);
  }

  @Delete('api/admin/posts/:id')
  @Header('Cache-Control', 'no-store')
  async deletePost(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    await this.municipalityPostsService.archive(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: MunicipalityPostInput) {
    const type = this.parseType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const publishedAt = this.requireDate(payload.publishedAt, 'publishedAt');
    const status = payload.status ? this.parseStatus(payload.status) : undefined;
    const priority = payload.priority
      ? this.parsePriority(payload.priority)
      : undefined;
    const endsAt = payload.endsAt
      ? this.requireDate(payload.endsAt, 'endsAt')
      : undefined;

    if (type === 'WARNING' && !priority) {
      throw new BadRequestException('priority ist erforderlich');
    }

    return {
      type,
      title,
      body,
      publishedAt,
      status,
      priority,
      endsAt,
    };
  }

  private validatePatch(payload: MunicipalityPostPatch) {
    const patch: MunicipalityPostPatch = {};
    if (payload.type !== undefined) {
      patch.type = this.parseType(payload.type);
    }
    if (payload.title !== undefined) {
      patch.title = this.requireString(payload.title, 'title');
    }
    if (payload.body !== undefined) {
      patch.body = this.requireString(payload.body, 'body');
    }
    if (payload.publishedAt !== undefined) {
      patch.publishedAt = this.requireDate(payload.publishedAt, 'publishedAt');
    }
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }
    if (payload.priority !== undefined) {
      patch.priority = this.parsePriority(payload.priority);
    }
    if (payload.endsAt !== undefined) {
      patch.endsAt = this.requireDate(payload.endsAt, 'endsAt');
    }

    if (patch.type === 'WARNING' && patch.priority === undefined) {
      throw new BadRequestException('priority ist erforderlich');
    }

    return patch;
  }

  private parseType(value: string): PostType {
    const normalized = value.trim().toUpperCase() as PostType;
    if (!['NEWS', 'WARNING'].includes(normalized)) {
      throw new BadRequestException('type ist ungültig');
    }
    return normalized;
  }

  private parseStatus(value: string): PostStatus {
    const normalized = value.trim().toUpperCase() as PostStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parsePriority(value: string): PostPriority {
    const normalized = value.trim().toUpperCase() as PostPriority;
    if (!['HIGH', 'MEDIUM', 'LOW'].includes(normalized)) {
      throw new BadRequestException('priority ist ungültig');
    }
    return normalized;
  }

  private parseDate(value: string | undefined, field: string) {
    if (!value) {
      return undefined;
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein gültiger ISO-8601-String sein`);
    }
    return new Date(parsed);
  }

  private requireDate(value: string | undefined, field: string) {
    if (!value) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein gültiger ISO-8601-String sein`);
    }
    return new Date(parsed).toISOString();
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }

  private parsePositiveNumber(value: string, field: string) {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException(`${field} muss eine positive Zahl sein`);
    }
    return parsed;
  }
}
