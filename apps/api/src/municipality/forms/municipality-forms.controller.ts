import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../../admin/admin.guard';
import { requireTenant } from '../../tenant/tenant-auth';
import {
  MunicipalityFormLink,
  MunicipalityFormLinkInput,
} from './municipality-forms.types';
import { MunicipalityFormsService } from './municipality-forms.service';

@Controller()
export class MunicipalityFormsController {
  constructor(private readonly municipalityFormsService: MunicipalityFormsService) {}

  @Get('api/forms')
  @Header('Cache-Control', 'private, max-age=30')
  async listForms(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('category') category?: string,
  ): Promise<MunicipalityFormLink[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityFormsService.list(tenantId, {
      category: category?.trim() || undefined,
    });
  }

  @Get('api/admin/forms')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async listAdminForms(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('category') category?: string,
  ): Promise<MunicipalityFormLink[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityFormsService.list(tenantId, {
      category: category?.trim() || undefined,
    });
  }

  @Put('api/admin/forms/bulk')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async upsertForms(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityFormLinkInput[],
  ): Promise<MunicipalityFormLink[]> {
    const tenantId = requireTenant(headers);
    const inputs = this.validatePayload(payload);
    return this.municipalityFormsService.upsertMany(tenantId, inputs);
  }

  private validatePayload(
    payload: MunicipalityFormLinkInput[],
  ): MunicipalityFormLinkInput[] {
    if (!payload || !Array.isArray(payload)) {
      throw new BadRequestException('forms muss ein Array sein');
    }
    if (payload.length === 0) {
      throw new BadRequestException('forms darf nicht leer sein');
    }
    return payload.map((entry, index) => ({
      category: this.requireString(entry.category, `forms[${index}].category`),
      title: this.requireString(entry.title, `forms[${index}].title`),
      url: this.validateUrl(entry.url, `forms[${index}].url`),
    }));
  }

  private validateUrl(value: string | undefined, field: string) {
    const trimmed = this.requireString(value, field);
    try {
      const parsed = new URL(trimmed);
      if (!['http:', 'https:'].includes(parsed.protocol)) {
        throw new Error('invalid protocol');
      }
      return trimmed;
    } catch {
      throw new BadRequestException(`${field} muss http oder https sein`);
    }
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }
}
