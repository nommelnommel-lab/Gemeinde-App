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
import { MunicipalityServicesService } from './municipality-services.service';
import {
  MunicipalityService,
  MunicipalityServiceInput,
  MunicipalityServicePatch,
  ServiceStatus,
} from './municipality-services.types';

@Controller()
export class MunicipalityServicesController {
  constructor(
    private readonly municipalityServicesService: MunicipalityServicesService,
  ) {}

  @Get('api/services')
  @Header('Cache-Control', 'private, max-age=30')
  async getServices(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') query?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ): Promise<MunicipalityService[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityServicesService.list(tenantId, {
      query: query?.trim() || undefined,
      status: status ? this.parseStatus(status) : undefined,
      limit: limit ? this.parseLimit(limit) : undefined,
    });
  }

  @Get('api/services/:id')
  @Header('Cache-Control', 'private, max-age=30')
  async getService(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<MunicipalityService> {
    const tenantId = requireTenant(headers);
    return this.municipalityServicesService.getById(tenantId, id);
  }

  @Post('api/admin/services')
  @Header('Cache-Control', 'no-store')
  async createService(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityServiceInput,
  ): Promise<MunicipalityService> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.municipalityServicesService.create(tenantId, input);
  }

  @Patch('api/admin/services/:id')
  @Header('Cache-Control', 'no-store')
  async updateService(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: MunicipalityServicePatch,
  ): Promise<MunicipalityService> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.municipalityServicesService.update(tenantId, id, patch);
  }

  @Delete('api/admin/services/:id')
  @Header('Cache-Control', 'no-store')
  async deleteService(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    await this.municipalityServicesService.archive(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: MunicipalityServiceInput) {
    const name = this.requireString(payload.name, 'name');
    const description = this.requireString(payload.description, 'description');
    const category = payload.category?.trim() || undefined;
    const url = payload.url ? this.validateUrl(payload.url) : undefined;
    const status = payload.status ? this.parseStatus(payload.status) : undefined;
    return {
      name,
      description,
      category,
      url,
      status,
      featured: payload.featured,
    };
  }

  private validatePatch(payload: MunicipalityServicePatch) {
    const patch: MunicipalityServicePatch = {};
    if (payload.name !== undefined) {
      patch.name = this.requireString(payload.name, 'name');
    }
    if (payload.description !== undefined) {
      patch.description = this.requireString(payload.description, 'description');
    }
    if (payload.category !== undefined) {
      patch.category = payload.category.trim() || undefined;
    }
    if (payload.url !== undefined) {
      patch.url = payload.url ? this.validateUrl(payload.url) : undefined;
    }
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }
    if (payload.featured !== undefined) {
      patch.featured = payload.featured;
    }
    return patch;
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

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private parseStatus(value: string): ServiceStatus {
    const normalized = value.trim().toUpperCase() as ServiceStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }
}
