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
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../../admin/admin.guard';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityVerwaltungService } from './municipality-verwaltung.service';
import {
  VerwaltungItem,
  VerwaltungItemInput,
  VerwaltungItemKind,
  VerwaltungItemPatch,
  VerwaltungItemStatus,
} from './municipality-verwaltung.types';

@Controller()
export class MunicipalityVerwaltungController {
  constructor(
    private readonly verwaltungService: MunicipalityVerwaltungService,
  ) {}

  @Get('api/verwaltung/items')
  @Header('Cache-Control', 'private, max-age=30')
  async getItems(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('kind') kind?: string,
    @Query('category') category?: string,
    @Query('q') query?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ): Promise<VerwaltungItem[]> {
    const tenantId = requireTenant(headers);
    return this.verwaltungService.list(tenantId, {
      kind: kind ? this.parseKind(kind) : undefined,
      category: category?.trim() || undefined,
      query: query?.trim() || undefined,
      status: 'PUBLISHED',
      limit: limit ? this.parseLimit(limit) : undefined,
      offset: offset ? this.parseOffset(offset) : undefined,
    });
  }

  @Get('api/verwaltung/items/:id')
  @Header('Cache-Control', 'private, max-age=30')
  async getItem(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<VerwaltungItem> {
    const tenantId = requireTenant(headers);
    return this.verwaltungService.getById(tenantId, id, {
      status: 'PUBLISHED',
    });
  }

  @Get('api/admin/verwaltung/items')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async getAdminItems(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('kind') kind?: string,
    @Query('category') category?: string,
    @Query('q') query?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ): Promise<VerwaltungItem[]> {
    const tenantId = requireTenant(headers);
    return this.verwaltungService.list(tenantId, {
      kind: kind ? this.parseKind(kind) : undefined,
      category: category?.trim() || undefined,
      query: query?.trim() || undefined,
      limit: limit ? this.parseLimit(limit) : undefined,
      offset: offset ? this.parseOffset(offset) : undefined,
    });
  }

  @Post('api/admin/verwaltung/items')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async createItem(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: VerwaltungItemInput,
  ): Promise<VerwaltungItem> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.verwaltungService.create(tenantId, input);
  }

  @Patch('api/admin/verwaltung/items/:id')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async updateItem(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: VerwaltungItemPatch,
  ): Promise<VerwaltungItem> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.verwaltungService.update(tenantId, id, patch);
  }

  @Delete('api/admin/verwaltung/items/:id')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async deleteItem(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<{ ok: true }> {
    const tenantId = requireTenant(headers);
    await this.verwaltungService.hide(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: VerwaltungItemInput): VerwaltungItemInput {
    return {
      kind: this.parseKind(payload.kind),
      category: this.requireString(payload.category, 'category'),
      title: this.requireString(payload.title, 'title'),
      description: payload.description?.trim() || null,
      url: this.validateUrl(payload.url),
      tags: this.parseTags(payload.tags),
      status: payload.status ? this.parseStatus(payload.status) : undefined,
      sortOrder: payload.sortOrder ?? 0,
      metadata: payload.metadata,
    };
  }

  private validatePatch(payload: VerwaltungItemPatch): VerwaltungItemPatch {
    const patch: VerwaltungItemPatch = {};
    if (payload.kind !== undefined) {
      patch.kind = this.parseKind(payload.kind);
    }
    if (payload.category !== undefined) {
      patch.category = this.requireString(payload.category, 'category');
    }
    if (payload.title !== undefined) {
      patch.title = this.requireString(payload.title, 'title');
    }
    if (payload.description !== undefined) {
      patch.description = payload.description?.trim() || null;
    }
    if (payload.url !== undefined) {
      patch.url = this.validateUrl(payload.url);
    }
    if (payload.tags !== undefined) {
      patch.tags = this.parseTags(payload.tags);
    }
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }
    if (payload.sortOrder !== undefined) {
      patch.sortOrder = payload.sortOrder ?? 0;
    }
    if (payload.metadata !== undefined) {
      patch.metadata = payload.metadata;
    }
    return patch;
  }

  private parseKind(value?: string): VerwaltungItemKind {
    const normalized = (value ?? '').trim().toUpperCase();
    if (normalized === 'FORM' || normalized === 'LINK') {
      return normalized;
    }
    throw new BadRequestException('kind ist ungültig');
  }

  private parseStatus(value: string): VerwaltungItemStatus {
    const normalized = value.trim().toUpperCase() as VerwaltungItemStatus;
    if (!['PUBLISHED', 'HIDDEN'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parseTags(tags?: string[]) {
    if (!Array.isArray(tags)) {
      return [];
    }
    return tags
      .map((tag) => tag.trim())
      .filter((tag) => tag.length > 0);
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
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
      throw new BadRequestException('offset muss >= 0 sein');
    }
    return parsed;
  }
}
