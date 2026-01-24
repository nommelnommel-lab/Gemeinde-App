import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Headers,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { isUUID } from 'class-validator';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { AuthService } from './auth.service';
import { ResidentsService } from './residents.service';
import { ActivationCodeCreateDto } from './dto/admin-activation-code.dto';

type BulkActivationCodeEntry = {
  residentId: string;
  expiresInDays?: number;
};

type BulkActivationCodeRequest = {
  items: BulkActivationCodeEntry[];
  expiresInDays?: number;
};

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
    const expiresInDays =
      this.normalizeOptionalExpiresInDays(payload.expiresInDays) ??
      this.defaultExpiresInDays();
    const expiresAt = this.resolveExpiry(expiresInDays);

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
    @Body() payload: unknown,
  ) {
    const tenantId = requireTenant(headers);
    const request = this.normalizeBulkPayload(payload);
    const created: Array<{
      residentId: string;
      code: string;
      expiresAt: string;
    }> = [];
    const skipped: Array<{ residentId: string; reason: string }> = [];

    for (let index = 0; index < request.items.length; index += 1) {
      const entry = request.items[index];
      try {
        const resident = await this.requireResident(tenantId, entry.residentId);
        const alreadyActivated = await this.authService.isResidentActivated(
          tenantId,
          resident.id,
        );
        if (alreadyActivated) {
          skipped.push({
            residentId: resident.id,
            reason: 'Bewohner ist bereits aktiviert',
          });
          continue;
        }
        const expiresInDays =
          entry.expiresInDays ??
          request.expiresInDays ??
          this.defaultExpiresInDays();
        const expiresAt = this.resolveExpiry(expiresInDays);
        const result = await this.authService.createActivationCodeForResident({
          tenantId,
          residentId: resident.id,
          expiresAt,
          createdBy: 'admin',
        });
        created.push({
          residentId: resident.id,
          code: result.code,
          expiresAt: result.expiresAt,
        });
      } catch (error) {
        skipped.push({
          residentId: entry.residentId,
          reason: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    return { created, skipped };
  }

  private resolveExpiry(expiresInDays: number) {
    const date = new Date();
    date.setDate(date.getDate() + expiresInDays);
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

  private normalizeBulkPayload(payload: unknown): BulkActivationCodeRequest {
    if (!payload || typeof payload !== 'object') {
      throw new BadRequestException('payload muss ein Array oder Objekt sein');
    }

    const record = payload as Record<string, unknown>;
    if (Array.isArray(record.residentIds)) {
      if (record.residentIds.length === 0) {
        throw new BadRequestException('residentIds darf nicht leer sein');
      }
      const expiresInDays = this.normalizeOptionalExpiresInDays(
        record.expiresInDays,
      );
      return {
        items: record.residentIds.map((residentId, index) => ({
          residentId: this.requireResidentId(
            residentId,
            `residentIds[${index}]`,
          ),
          expiresInDays,
        })),
        expiresInDays,
      };
    }

    throw new BadRequestException(
      'payload muss residentIds, items oder entries enthalten',
    );
  }

  private requireResidentId(value: unknown, label: string) {
    if (typeof value !== 'string' || !isUUID(value)) {
      throw new BadRequestException(`${label} ist ungültig`);
    }
    return value;
  }

  private normalizeOptionalExpiresInDays(value: unknown) {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return this.normalizeExpiresInDays(value);
  }

  private normalizeExpiresInDays(value: unknown) {
    const resolved =
      typeof value === 'number' ? value : Number.parseInt(String(value), 10);
    if (!Number.isInteger(resolved)) {
      throw new BadRequestException('expiresInDays muss eine Zahl sein');
    }
    if (resolved < 1 || resolved > 365) {
      throw new BadRequestException(
        'expiresInDays muss zwischen 1 und 365 liegen',
      );
    }
    return resolved;
  }

  private defaultExpiresInDays() {
    return 30;
  }

}
