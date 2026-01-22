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
import { MunicipalityPlacesService } from './municipality-places.service';
import {
  MunicipalityPlace,
  MunicipalityPlaceInput,
  MunicipalityPlacePatch,
  PlaceStatus,
} from './municipality-places.types';

@Controller()
export class MunicipalityPlacesController {
  constructor(
    private readonly municipalityPlacesService: MunicipalityPlacesService,
  ) {}

  @Get('api/places')
  @Header('Cache-Control', 'private, max-age=30')
  async getPlaces(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('bbox') bbox?: string,
  ): Promise<MunicipalityPlace[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityPlacesService.list(tenantId, {
      type: type?.trim() || undefined,
      status: status ? this.parseStatus(status) : undefined,
      bbox: bbox ? this.parseBbox(bbox) : undefined,
    });
  }

  @Get('api/places/:id')
  @Header('Cache-Control', 'private, max-age=30')
  async getPlace(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<MunicipalityPlace> {
    const tenantId = requireTenant(headers);
    return this.municipalityPlacesService.getById(tenantId, id);
  }

  @Post('api/admin/places')
  @Header('Cache-Control', 'no-store')
  async createPlace(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityPlaceInput,
  ): Promise<MunicipalityPlace> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.municipalityPlacesService.create(tenantId, input);
  }

  @Patch('api/admin/places/:id')
  @Header('Cache-Control', 'no-store')
  async updatePlace(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: MunicipalityPlacePatch,
  ): Promise<MunicipalityPlace> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.municipalityPlacesService.update(tenantId, id, patch);
  }

  @Delete('api/admin/places/:id')
  @Header('Cache-Control', 'no-store')
  async deletePlace(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    await this.municipalityPlacesService.archive(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: MunicipalityPlaceInput) {
    const name = this.requireString(payload.name, 'name');
    const description = this.requireString(payload.description, 'description');
    const type = this.requireString(payload.type, 'type');
    const address = payload.address?.trim() || undefined;
    const lat = payload.lat;
    const lon = payload.lon;
    this.validateCoordinates(lat, lon);
    const status = payload.status ? this.parseStatus(payload.status) : undefined;
    return {
      name,
      description,
      type,
      address,
      lat,
      lon,
      status,
    };
  }

  private validatePatch(payload: MunicipalityPlacePatch) {
    const patch: MunicipalityPlacePatch = {};
    if (payload.name !== undefined) {
      patch.name = this.requireString(payload.name, 'name');
    }
    if (payload.description !== undefined) {
      patch.description = this.requireString(payload.description, 'description');
    }
    if (payload.type !== undefined) {
      patch.type = this.requireString(payload.type, 'type');
    }
    if (payload.address !== undefined) {
      patch.address = payload.address.trim() || undefined;
    }
    if (payload.lat !== undefined) {
      patch.lat = payload.lat;
    }
    if (payload.lon !== undefined) {
      patch.lon = payload.lon;
    }
    this.validateCoordinates(patch.lat, patch.lon);
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }
    return patch;
  }

  private parseStatus(value: string): PlaceStatus {
    const normalized = value.trim().toUpperCase() as PlaceStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parseBbox(value: string) {
    const parts = value.split(',').map((part) => Number.parseFloat(part.trim()));
    if (parts.length !== 4 || parts.some((part) => Number.isNaN(part))) {
      throw new BadRequestException('bbox ist ungültig');
    }
    const [minLon, minLat, maxLon, maxLat] = parts;
    return { minLon, minLat, maxLon, maxLat };
  }

  private validateCoordinates(lat?: number, lon?: number) {
    if (lat === undefined && lon === undefined) {
      return;
    }
    if (lat === undefined || lon === undefined) {
      throw new BadRequestException('lat und lon müssen gemeinsam gesetzt werden');
    }
    if (lat < 47 || lat > 55) {
      throw new BadRequestException('lat ist außerhalb des gültigen Bereichs');
    }
    if (lon < 5 || lon > 16) {
      throw new BadRequestException('lon ist außerhalb des gültigen Bereichs');
    }
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }
}
