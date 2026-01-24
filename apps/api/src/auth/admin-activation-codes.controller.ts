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
    const expiresAt = this.resolveExpiry(payload.expiresInDays);

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
    const rows: Array<{
      displayName: string;
      postalCode: string;
      houseNumber: string;
      code: string;
      expiresAt: string;
    }> = [];
    const errors: Array<{ index: number; residentId?: string; message: string }> = [];

    for (let index = 0; index < request.items.length; index += 1) {
      const entry = request.items[index];
      try {
        const resident = await this.requireResident(tenantId, entry.residentId);
        const expiresAt = this.resolveExpiry(entry.expiresInDays);
        const result = await this.authService.createActivationCodeForResident({
          tenantId,
          residentId: resident.id,
          expiresAt,
          createdBy: 'admin',
        });
        rows.push({
          displayName: this.displayName(resident.firstName, resident.lastName),
          postalCode: resident.postalCode,
          houseNumber: resident.houseNumber,
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

    return { rows, errors, processed: request.items.length };
  }

  private resolveExpiry(expiresInDays?: number) {
    const resolvedDays = this.normalizeExpiresInDays(expiresInDays);
    const date = new Date();
    date.setDate(date.getDate() + resolvedDays);
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

  private normalizeBulkPayload(payload: unknown) {
    if (Array.isArray(payload)) {
      if (payload.length === 0) {
        throw new BadRequestException('residentIds darf nicht leer sein');
      }
      return {
        items: payload.map((residentId, index) => ({
          residentId: this.requireResidentId(
            residentId,
            `residentIds[${index}]`,
          ),
        })),
      };
    }

    if (!payload || typeof payload !== 'object') {
      throw new BadRequestException('payload muss ein Array oder Objekt sein');
    }

    const record = payload as Record<string, unknown>;
    if (Array.isArray(record.items)) {
      if (record.items.length === 0) {
        throw new BadRequestException('items darf nicht leer sein');
      }
      return {
        items: record.items.map((item, index) => {
          if (!item || typeof item !== 'object') {
            throw new BadRequestException(`items[${index}] ist ungültig`);
          }
          const itemRecord = item as Record<string, unknown>;
          return {
            residentId: this.requireResidentId(
              itemRecord.residentId,
              `items[${index}].residentId`,
            ),
            expiresInDays: this.normalizeExpiresInDays(itemRecord.expiresInDays),
          };
        }),
      };
    }

    if (Array.isArray(record.residentIds)) {
      if (record.residentIds.length === 0) {
        throw new BadRequestException('residentIds darf nicht leer sein');
      }
      const expiresInDays = this.normalizeExpiresInDays(record.expiresInDays);
      return {
        items: record.residentIds.map((residentId, index) => ({
          residentId: this.requireResidentId(
            residentId,
            `residentIds[${index}]`,
          ),
          expiresInDays,
        })),
      };
    }

    throw new BadRequestException('payload muss residentIds oder items enthalten');
  }

  private requireResidentId(value: unknown, label: string) {
    if (typeof value !== 'string' || !isUUID(value)) {
      throw new BadRequestException(`${label} ist ungültig`);
    }
    return value;
  }

  private normalizeExpiresInDays(value: unknown) {
    if (value === undefined || value === null || value === '') {
      return 30;
    }
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

  private displayName(firstName: string, lastName: string) {
    const initial = lastName.trim().charAt(0);
    return `${firstName.trim()} ${initial}.`;
  }
}
