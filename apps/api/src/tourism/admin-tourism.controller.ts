import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { TourismService } from './tourism.service';
import {
  TourismItemEntity,
  TourismItemStatus,
  TourismItemType,
} from './tourism.types';

type TourismPayload = {
  type?: TourismItemType;
  title?: string;
  body?: string;
  metadata?: Record<string, unknown>;
  status?: TourismItemStatus;
};

@Controller('api/admin/tourism')
@UseGuards(AdminGuard)
export class AdminTourismController {
  constructor(private readonly tourismService: TourismService) {}

  @Get()
  async list(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('q') query?: string,
  ): Promise<TourismItemEntity[]> {
    const tenantId = requireTenant(headers);
    const parsedType = type ? this.parseType(type) : undefined;
    const parsedStatus = status ? this.parseStatus(status) : undefined;
    const parsedLimit = limit ? this.parseNumber(limit, 'limit') : undefined;
    const parsedOffset = offset ? this.parseNumber(offset, 'offset') : undefined;
    return this.tourismService.list(tenantId, {
      type: parsedType,
      status: parsedStatus,
      limit: parsedLimit,
      offset: parsedOffset,
      query,
      includeHidden: true,
    });
  }

  @Post()
  async create(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: TourismPayload,
  ): Promise<TourismItemEntity> {
    const tenantId = requireTenant(headers);
    const type = this.requireType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const status = payload.status;
    return this.tourismService.create({
      tenantId,
      type,
      title,
      body,
      metadata: payload.metadata ?? {},
      status,
    });
  }

  @Patch(':id')
  async update(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: TourismPayload,
  ): Promise<TourismItemEntity> {
    const tenantId = requireTenant(headers);
    return this.tourismService.update(tenantId, id, {
      type: payload.type,
      title: payload.title?.trim(),
      body: payload.body?.trim(),
      metadata: payload.metadata,
      status: payload.status,
    });
  }

  @Delete(':id')
  async remove(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<{ ok: true }> {
    const tenantId = requireTenant(headers);
    await this.tourismService.hide(tenantId, id);
    return { ok: true };
  }

  private parseType(value: string): TourismItemType {
    const normalized = value.trim().toUpperCase().replace('-', '_');
    if (
      normalized === 'HIKING_ROUTE' ||
      normalized === 'SIGHT' ||
      normalized === 'LEISURE' ||
      normalized === 'RESTAURANT'
    ) {
      return normalized as TourismItemType;
    }
    throw new BadRequestException('type ist ungültig');
  }

  private parseStatus(value: string): TourismItemStatus {
    const normalized = value.trim().toUpperCase();
    if (normalized === 'PUBLISHED' || normalized === 'HIDDEN') {
      return normalized as TourismItemStatus;
    }
    throw new BadRequestException('status ist ungültig');
  }

  private parseNumber(value: string, label: string) {
    const parsed = Number.parseInt(value, 10);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${label} ist ungültig`);
    }
    return parsed;
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private requireType(value?: TourismItemType) {
    if (!value) {
      throw new BadRequestException('type ist erforderlich');
    }
    return value;
  }
}
