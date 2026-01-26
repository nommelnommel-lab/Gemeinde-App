import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { TouristCodeGenerateDto } from './dto/admin-tourist-codes.dto';
import { TouristAccessCodesService } from './tourist-access-codes.service';
import { TouristAccessCodeStatus } from './tourist-access-codes.model';

@Controller('api/admin/tourist-codes')
@UseGuards(AdminGuard)
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class AdminTouristCodesController {
  constructor(private readonly touristCodes: TouristAccessCodesService) {}

  @Post('generate')
  async generateCodes(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: TouristCodeGenerateDto,
  ) {
    const tenantId = requireTenant(headers);
    const codes = await this.touristCodes.generateCodes({
      tenantId,
      durationDays: payload.durationDays,
      amount: payload.amount,
    });
    return { codes, durationDays: payload.durationDays };
  }

  @Get()
  async listCodes(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('status') status?: string,
    @Query('durationDays') durationDays?: string,
  ) {
    const tenantId = requireTenant(headers);
    const normalizedStatus = this.normalizeStatus(status);
    const normalizedDuration = this.normalizeDuration(durationDays);
    const codes = await this.touristCodes.listCodes({
      tenantId,
      status: normalizedStatus,
      durationDays: normalizedDuration,
    });

    return {
      items: codes.map((code) => ({
        id: code.id,
        durationDays: code.durationDays,
        status: code.status,
        redeemedAt: code.redeemedAt ?? null,
        redeemedByDeviceId: code.redeemedByDeviceId ?? null,
        createdAt: code.createdAt,
      })),
    };
  }

  @Post(':id/revoke')
  async revoke(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    const updated = await this.touristCodes.revoke(tenantId, id);
    return {
      id: updated.id,
      status: updated.status,
    };
  }

  private normalizeStatus(value?: string) {
    if (!value) {
      return undefined;
    }
    const normalized = value.trim().toUpperCase();
    if (!(normalized in TouristAccessCodeStatus)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized as TouristAccessCodeStatus;
  }

  private normalizeDuration(value?: string) {
    if (!value) {
      return undefined;
    }
    const parsed = Number.parseInt(value, 10);
    if (![7, 14, 30].includes(parsed)) {
      throw new BadRequestException('durationDays ist ungültig');
    }
    return parsed as 7 | 14 | 30;
  }
}
