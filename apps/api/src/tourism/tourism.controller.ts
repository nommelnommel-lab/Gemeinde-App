import {
  BadRequestException,
  Controller,
  Get,
  Headers,
  Param,
  Query,
} from '@nestjs/common';
import { requireTenant } from '../tenant/tenant-auth';
import { TourismService } from './tourism.service';
import { TourismItemEntity, TourismItemType } from './tourism.types';

@Controller('api/tourism')
export class TourismController {
  constructor(private readonly tourismService: TourismService) {}

  @Get()
  async list(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('type') type?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('q') query?: string,
  ): Promise<TourismItemEntity[]> {
    const tenantId = requireTenant(headers);
    const parsedType = type ? this.parseType(type) : undefined;
    const parsedLimit = limit ? this.parseNumber(limit, 'limit') : undefined;
    const parsedOffset = offset ? this.parseNumber(offset, 'offset') : undefined;
    return this.tourismService.list(tenantId, {
      type: parsedType,
      limit: parsedLimit,
      offset: parsedOffset,
      query,
      includeHidden: false,
      status: 'PUBLISHED',
    });
  }

  @Get(':id')
  async getById(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<TourismItemEntity> {
    const tenantId = requireTenant(headers);
    return this.tourismService.getById(tenantId, id);
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

  private parseNumber(value: string, label: string) {
    const parsed = Number.parseInt(value, 10);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${label} ist ungültig`);
    }
    return parsed;
  }
}
