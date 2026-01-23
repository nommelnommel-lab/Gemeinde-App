import {
  BadRequestException,
  Body,
  Controller,
  Header,
  Headers,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../../admin/admin.guard';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityEventsService } from '../events/municipality-events.service';
import {
  MunicipalityEvent,
  MunicipalityEventInput,
} from '../events/municipality-events.types';
import { MunicipalityPostsService } from '../posts/municipality-posts.service';
import {
  MunicipalityPost,
  MunicipalityPostInput,
  PostPriority,
  PostStatus,
  PostType,
} from '../posts/municipality-posts.types';
import { MunicipalityServicesService } from '../services/municipality-services.service';
import {
  MunicipalityService,
  MunicipalityServiceInput,
  ServiceStatus,
} from '../services/municipality-services.types';

@Controller()
export class MunicipalityImportController {
  constructor(
    private readonly municipalityEventsService: MunicipalityEventsService,
    private readonly municipalityPostsService: MunicipalityPostsService,
    private readonly municipalityServicesService: MunicipalityServicesService,
  ) {}

  @Post('api/admin/import/events')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async importEvents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityEventInput[],
  ) {
    const tenantId = requireTenant(headers);
    const inputs = this.ensureArray(payload, 'events');
    return this.importBatch(inputs, (entry) => {
      const validated = this.validateEvent(entry);
      return this.municipalityEventsService.create(tenantId, validated);
    });
  }

  @Post('api/admin/import/posts')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async importPosts(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityPostInput[],
  ) {
    const tenantId = requireTenant(headers);
    const inputs = this.ensureArray(payload, 'posts');
    return this.importBatch(inputs, (entry) => {
      const validated = this.validatePost(entry);
      return this.municipalityPostsService.create(tenantId, validated);
    });
  }

  @Post('api/admin/import/services')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async importServices(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityServiceInput[],
  ) {
    const tenantId = requireTenant(headers);
    const inputs = this.ensureArray(payload, 'services');
    return this.importBatch(inputs, (entry) => {
      const validated = this.validateService(entry);
      return this.municipalityServicesService.create(tenantId, validated);
    });
  }

  private async importBatch<T>(
    entries: T[],
    handler: (entry: T) => Promise<
      MunicipalityEvent | MunicipalityPost | MunicipalityService
    >,
  ) {
    const items: Array<
      MunicipalityEvent | MunicipalityPost | MunicipalityService
    > = [];
    const errors: Array<{ index: number; message: string }> = [];

    for (let index = 0; index < entries.length; index += 1) {
      try {
        const created = await handler(entries[index]);
        items.push(created);
      } catch (error) {
        errors.push({
          index,
          message: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    if (errors.length > 0 && items.length === 0) {
      throw new BadRequestException({
        message: 'Import fehlgeschlagen',
        errors,
      });
    }

    return {
      created: items.length,
      errors,
      items,
    };
  }

  private ensureArray<T>(payload: T[] | undefined, label: string): T[] {
    if (!payload || !Array.isArray(payload)) {
      throw new BadRequestException(`${label} muss ein Array sein`);
    }
    if (payload.length === 0) {
      throw new BadRequestException(`${label} darf nicht leer sein`);
    }
    return payload;
  }

  private validateEvent(payload: MunicipalityEventInput): MunicipalityEventInput {
    const title = this.requireString(payload.title, 'title');
    const description = this.requireString(payload.description, 'description');
    const location = this.requireString(payload.location, 'location');
    const startAt = this.requireDate(payload.startAt, 'startAt');
    const endAt = payload.endAt
      ? this.requireDate(payload.endAt, 'endAt')
      : undefined;

    if (endAt && Date.parse(endAt) < Date.parse(startAt)) {
      throw new BadRequestException('endAt muss nach startAt liegen');
    }

    return {
      title,
      description,
      location,
      startAt,
      endAt,
      status: payload.status,
    };
  }

  private validatePost(payload: MunicipalityPostInput): MunicipalityPostInput {
    const type = this.parsePostType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const publishedAt = this.requireDate(payload.publishedAt, 'publishedAt');
    const status = payload.status ? this.parsePostStatus(payload.status) : undefined;
    const priority = payload.priority
      ? this.parsePostPriority(payload.priority)
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

  private validateService(
    payload: MunicipalityServiceInput,
  ): MunicipalityServiceInput {
    const name = this.requireString(payload.name, 'name');
    const description = this.requireString(payload.description, 'description');
    const category = payload.category?.trim() || undefined;
    const status = payload.status ? this.parseServiceStatus(payload.status) : undefined;
    const url = payload.url ? this.validateUrl(payload.url) : undefined;
    return {
      name,
      description,
      category,
      status,
      url,
      featured: payload.featured,
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private requireDate(value: string | undefined, field: string) {
    if (!value) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein gültiger ISO-8601-String sein`);
    }
    return value;
  }

  private parsePostType(value: PostType | string | undefined): PostType {
    if (!value) {
      throw new BadRequestException('type ist erforderlich');
    }
    const normalized = value.toString().trim().toUpperCase() as PostType;
    if (!['NEWS', 'WARNING'].includes(normalized)) {
      throw new BadRequestException('type ist ungültig');
    }
    return normalized;
  }

  private parsePostStatus(value: PostStatus | string): PostStatus {
    const normalized = value.toString().trim().toUpperCase() as PostStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parsePostPriority(value: PostPriority | string): PostPriority {
    const normalized = value.toString().trim().toUpperCase() as PostPriority;
    if (!['HIGH', 'MEDIUM', 'LOW'].includes(normalized)) {
      throw new BadRequestException('priority ist ungültig');
    }
    return normalized;
  }

  private parseServiceStatus(value: ServiceStatus | string): ServiceStatus {
    const normalized = value.toString().trim().toUpperCase() as ServiceStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private validateUrl(value: string) {
    const trimmed = value.trim();
    try {
      const parsed = new URL(trimmed);
      if (!['http:', 'https:'].includes(parsed.protocol)) {
        throw new Error('invalid protocol');
      }
      return trimmed;
    } catch {
      throw new BadRequestException('url muss http oder https sein');
    }
  }
}
