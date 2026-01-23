import {
  BadRequestException,
  Body,
  Controller,
  Header,
  Headers,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { ResidentsService } from './residents.service';

type ResidentPayload = {
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
};

@Controller('api/admin/residents')
@UseGuards(AdminGuard)
export class AdminResidentsController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  async createResident(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ResidentPayload,
  ) {
    const tenantId = requireTenant(headers);
    const normalized = this.normalizeResident(payload);
    const residentId = await this.residentsService.upsertResident(
      tenantId,
      normalized,
    );

    return { residentId };
  }

  @Post('bulk')
  @Header('Cache-Control', 'no-store')
  async bulkResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ResidentPayload[],
  ) {
    const tenantId = requireTenant(headers);
    if (!Array.isArray(payload) || payload.length === 0) {
      throw new BadRequestException('payload muss ein Array sein');
    }

    return this.residentsService.bulkUpsert(tenantId, payload);
  }

  private normalizeResident(payload: ResidentPayload): ResidentPayload {
    return {
      firstName: this.requireString(payload.firstName, 'firstName'),
      lastName: this.requireString(payload.lastName, 'lastName'),
      postalCode: this.requireString(payload.postalCode, 'postalCode'),
      houseNumber: this.requireString(payload.houseNumber, 'houseNumber'),
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }
}
