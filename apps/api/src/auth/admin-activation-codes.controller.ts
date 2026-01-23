import {
  Body,
  Controller,
  ForbiddenException,
  Headers,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { AuthService } from './auth.service';
import { ResidentsService } from './residents.service';
import {
  ActivationCodeBulkRequestDto,
  ActivationCodeCreateDto,
} from './dto/admin-activation-code.dto';

@Controller('api/admin/activation-codes')
@UseGuards(AdminGuard)
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class AdminActivationCodesController {
  constructor(
    private readonly authService: AuthService,
    private readonly residentsService: ResidentsService,
  ) {}

  @Post()
  async createActivationCode(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ActivationCodeCreateDto,
  ) {
    const tenantId = requireTenant(headers);
    const resident = await this.requireResident(tenantId, payload.residentId);
    const expiresAt = this.resolveExpiry(payload.expiresInDays ?? 30);

    const result = await this.authService.createActivationCodeForResident({
      tenantId,
      residentId: resident.id,
      expiresAt,
      createdBy: 'admin',
    });

    return {
      residentId: resident.id,
      code: result.code,
      expiresAt: result.expiresAt,
    };
  }

  @Post('bulk')
  async bulkActivationCodes(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ActivationCodeBulkRequestDto,
  ) {
    const tenantId = requireTenant(headers);
    const rows: Array<{ residentId: string; code: string; expiresAt: string }> =
      [];
    const errors: Array<{ index: number; residentId?: string; message: string }> =
      [];

    for (let index = 0; index < payload.items.length; index += 1) {
      const entry = payload.items[index];
      try {
        const resident = await this.requireResident(tenantId, entry.residentId);
        const expiresAt = this.resolveExpiry(entry.expiresInDays ?? 30);
        const result = await this.authService.createActivationCodeForResident({
          tenantId,
          residentId: resident.id,
          expiresAt,
          createdBy: 'admin',
        });
        rows.push({
          residentId: resident.id,
          code: result.code,
          expiresAt: result.expiresAt,
        });
      } catch (error) {
        errors.push({
          index,
          residentId: entry.residentId,
          message: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    return { rows, errors, processed: payload.items.length };
  }

  private resolveExpiry(expiresInDays: number) {
    const days = expiresInDays > 0 ? expiresInDays : 30;
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
  }

  private async requireResident(tenantId: string, residentId: string) {
    try {
      return await this.residentsService.getById(tenantId, residentId);
    } catch (error) {
      const otherTenant =
        await this.residentsService.findTenantForResidentId(residentId);
      if (otherTenant && otherTenant !== tenantId) {
        throw new ForbiddenException('Bewohner gehört zu einem anderen Tenant');
      }
      throw error;
    }
  }
}
