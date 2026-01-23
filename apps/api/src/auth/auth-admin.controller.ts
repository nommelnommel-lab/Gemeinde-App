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
import { ActivationCodesService } from './activation-codes.service';
import { ResidentsService } from './residents.service';
import { Resident } from './auth.types';

@Controller('api/admin')
@UseGuards(AdminGuard)
export class AuthAdminController {
  constructor(
    private readonly residentsService: ResidentsService,
    private readonly activationCodesService: ActivationCodesService,
  ) {}

  @Post('residents')
  @Header('Cache-Control', 'no-store')
  async createResident(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body()
    payload: {
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
    },
  ) {
    const tenantId = requireTenant(headers);
    const normalized = {
      firstName: this.requireString(payload.firstName, 'firstName'),
      lastName: this.requireString(payload.lastName, 'lastName'),
      postalCode: this.requireString(payload.postalCode, 'postalCode'),
      houseNumber: this.requireString(payload.houseNumber, 'houseNumber'),
    };
    const existing = await this.residentsService.findByAddress(
      tenantId,
      normalized.postalCode,
      normalized.houseNumber,
    );
    const resident = existing
      ? await this.residentsService.update(tenantId, existing.id, normalized)
      : await this.residentsService.create(tenantId, normalized);
    return { residentId: resident.id };
  }

  @Post('residents/bulk')
  @Header('Cache-Control', 'no-store')
  async bulkResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body()
    payload: Array<{
      firstName: string;
      lastName: string;
      postalCode: string;
      houseNumber: string;
      status?: Resident['status'];
    }>,
  ) {
    const tenantId = requireTenant(headers);
    if (!Array.isArray(payload) || payload.length === 0) {
      throw new BadRequestException('payload muss ein Array sein');
    }

    let created = 0;
    let updated = 0;
    const errors: Array<{ index: number; message: string }> = [];

    for (let index = 0; index < payload.length; index += 1) {
      try {
        const entry = payload[index];
        const normalized = {
          firstName: this.requireString(entry.firstName, 'firstName'),
          lastName: this.requireString(entry.lastName, 'lastName'),
          postalCode: this.requireString(entry.postalCode, 'postalCode'),
          houseNumber: this.requireString(entry.houseNumber, 'houseNumber'),
          status: entry.status,
        };

        const existing = await this.residentsService.findByAddress(
          tenantId,
          normalized.postalCode,
          normalized.houseNumber,
        );
        if (existing) {
          await this.residentsService.update(tenantId, existing.id, normalized);
          updated += 1;
        } else {
          await this.residentsService.create(tenantId, normalized);
          created += 1;
        }
      } catch (error) {
        errors.push({
          index,
          message: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    return { created, updated, errors, processed: payload.length };
  }

  @Post('activation-codes')
  @Header('Cache-Control', 'no-store')
  async createActivationCode(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: { residentId: string; expiresInDays?: number },
  ) {
    const tenantId = requireTenant(headers);
    const residentId = this.requireString(payload.residentId, 'residentId');
    await this.residentsService.getById(tenantId, residentId);
    const expiresAt = this.resolveExpiry(payload.expiresInDays);
    const result = await this.activationCodesService.createCode(
      tenantId,
      residentId,
      expiresAt,
    );

    return {
      residentId,
      code: result.code,
      expiresAt: result.activation.expiresAt,
    };
  }

  @Post('activation-codes/bulk')
  @Header('Cache-Control', 'no-store')
  async bulkActivationCodes(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body()
    payload: {
      residentIds?: string[];
      residents?: Array<{
        firstName: string;
        lastName: string;
        postalCode: string;
        houseNumber: string;
        status?: Resident['status'];
      }>;
      expiresInDays?: number;
    },
  ) {
    const tenantId = requireTenant(headers);
    const residentIds = payload.residentIds ?? [];
    const residentsPayload = payload.residents ?? [];

    if (residentIds.length === 0 && residentsPayload.length === 0) {
      throw new BadRequestException('residentIds oder residents erforderlich');
    }

    const expiresAt = this.resolveExpiry(payload.expiresInDays);
    const rows: Array<{
      displayName: string;
      postalCode: string;
      houseNumber: string;
      code: string;
      expiresAt: string;
    }> = [];

    for (const residentId of residentIds) {
      const resident = await this.residentsService.getById(tenantId, residentId);
      const { code, activation } = await this.activationCodesService.createCode(
        tenantId,
        residentId,
        expiresAt,
      );
      rows.push({
        displayName: `${resident.firstName} ${resident.lastName}`,
        postalCode: resident.postalCode,
        houseNumber: resident.houseNumber,
        code,
        expiresAt: activation.expiresAt,
      });
    }

    for (const residentPayload of residentsPayload) {
      const normalized = {
        firstName: this.requireString(residentPayload.firstName, 'firstName'),
        lastName: this.requireString(residentPayload.lastName, 'lastName'),
        postalCode: this.requireString(residentPayload.postalCode, 'postalCode'),
        houseNumber: this.requireString(residentPayload.houseNumber, 'houseNumber'),
        status: residentPayload.status,
      };

      const existing = await this.residentsService.findByAddress(
        tenantId,
        normalized.postalCode,
        normalized.houseNumber,
      );
      const resident = existing
        ? await this.residentsService.update(tenantId, existing.id, normalized)
        : await this.residentsService.create(tenantId, normalized);

      const { code, activation } = await this.activationCodesService.createCode(
        tenantId,
        resident.id,
        expiresAt,
      );
      rows.push({
        displayName: `${resident.firstName} ${resident.lastName}`,
        postalCode: resident.postalCode,
        houseNumber: resident.houseNumber,
        code,
        expiresAt: activation.expiresAt,
      });
    }

    return { rows };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private resolveExpiry(expiresInDays?: number) {
    const days = expiresInDays && expiresInDays > 0 ? expiresInDays : 14;
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
  }
}
