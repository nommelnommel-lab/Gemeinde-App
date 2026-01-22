import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Post,
  Query,
} from '@nestjs/common';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityWastePickupsService } from './municipality-waste-pickups.service';
import {
  MunicipalityWastePickup,
  MunicipalityWastePickupBulkPayload,
  MunicipalityWastePickupInput,
  WastePickupStatus,
} from './municipality-waste-pickups.types';

@Controller()
export class MunicipalityWastePickupsController {
  constructor(
    private readonly municipalityWastePickupsService: MunicipalityWastePickupsService,
  ) {}

  @Get('api/waste-pickups')
  @Header('Cache-Control', 'private, max-age=30')
  async getWastePickups(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('district') district?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ): Promise<MunicipalityWastePickup[]> {
    const tenantId = requireTenant(headers);
    if (!district || district.trim().length === 0) {
      throw new BadRequestException('district ist erforderlich');
    }
    const fromDate = this.parseDate(from, 'from') ?? new Date();
    const toDate = this.parseDate(to, 'to') ?? this.addDays(fromDate, 60);
    return this.municipalityWastePickupsService.list(tenantId, {
      district: district.trim(),
      from: fromDate,
      to: toDate,
    });
  }

  @Post('api/admin/waste-pickups/bulk')
  @Header('Cache-Control', 'no-store')
  async bulkImport(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityWastePickupBulkPayload,
  ) {
    const tenantId = requireTenant(headers);
    if (!payload || !Array.isArray(payload.pickups)) {
      throw new BadRequestException('pickups ist erforderlich');
    }
    const inputs = payload.pickups.map((entry) => this.validateInput(entry));
    return this.municipalityWastePickupsService.bulkUpsert(tenantId, inputs);
  }

  private validateInput(entry: MunicipalityWastePickupInput) {
    const district = this.requireString(entry.district, 'district');
    const wasteType = this.requireString(entry.wasteType, 'wasteType');
    const pickupDate = this.requireDate(entry.pickupDate, 'pickupDate');
    const status = entry.status ? this.parseStatus(entry.status) : undefined;
    return { district, wasteType, pickupDate, status };
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
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      throw new BadRequestException(`${field} muss ein Datum sein (YYYY-MM-DD)`);
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein Datum sein (YYYY-MM-DD)`);
    }
    return value;
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

  private parseStatus(value: string): WastePickupStatus {
    const normalized = value.trim().toUpperCase() as WastePickupStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private addDays(date: Date, days: number) {
    const next = new Date(date);
    next.setDate(next.getDate() + days);
    return next;
  }
}
