import {
  BadRequestException,
  Body,
  Controller,
  Header,
  Headers,
  Get,
  Post,
  Query,
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
    const residentId = await this.residentsService.createResident(
      tenantId,
      payload,
    );

    return { residentId };
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  async listResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') q?: string,
    @Query('limit') limit?: string,
  ) {
    const tenantId = requireTenant(headers);
    const resolvedLimit = limit ? Number.parseInt(limit, 10) : undefined;
    return this.residentsService.listResidents(tenantId, q, resolvedLimit);
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

    return this.residentsService.bulkCreateResidents(tenantId, payload);
  }
}
