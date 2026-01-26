import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Put,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../../admin/admin.guard';
import { requireTenant } from '../../tenant/tenant-auth';
import {
  MunicipalityProfile,
  MunicipalityProfilePayload,
  MunicipalityProfileLink,
  MunicipalityProfileOpeningHour,
  MunicipalityProfileEmergencyNumber,
} from './municipality-profile.types';
import { MunicipalityProfileService } from './municipality-profile.service';

@Controller()
export class MunicipalityProfileController {
  constructor(
    private readonly municipalityProfileService: MunicipalityProfileService,
  ) {}

  @Get('api/municipality/profile')
  @Header('Cache-Control', 'private, max-age=30')
  async getProfile(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ): Promise<MunicipalityProfile> {
    const tenantId = requireTenant(headers);
    return this.municipalityProfileService.getProfile(tenantId);
  }

  @Put('api/admin/municipality/profile')
  @UseGuards(AdminGuard)
  @Header('Cache-Control', 'no-store')
  async upsertProfile(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityProfilePayload,
  ): Promise<MunicipalityProfile> {
    const tenantId = requireTenant(headers);
    const validated = this.validatePayload(payload);
    return this.municipalityProfileService.upsertProfile(tenantId, validated);
  }

  private validatePayload(
    payload: MunicipalityProfilePayload,
  ): MunicipalityProfilePayload {
    const name = this.requireString(payload.name, 'name');
    if (!payload.address) {
      throw new BadRequestException('address ist erforderlich');
    }
    const street = this.requireString(payload.address.street, 'address.street');
    const zip = this.requireString(payload.address.zip, 'address.zip');
    const city = this.requireString(payload.address.city, 'address.city');
    const phone = this.requireString(payload.phone, 'phone');
    const fax = this.requireString(payload.fax, 'fax');
    const email = this.requireString(payload.email, 'email');
    const websiteUrl = this.validateUrl(payload.websiteUrl, 'websiteUrl');
    const openingHours = this.validateOpeningHours(payload.openingHours);
    const importantLinks = this.validateLinks(payload.importantLinks);
    const emergencyNumbers = this.validateEmergencyNumbers(
      payload.emergencyNumbers,
    );

    return {
      name,
      address: { street, zip, city },
      phone,
      fax,
      email,
      websiteUrl,
      openingHours,
      importantLinks,
      emergencyNumbers,
    };
  }

  private validateOpeningHours(
    payload: MunicipalityProfileOpeningHour[],
  ): MunicipalityProfileOpeningHour[] {
    if (!Array.isArray(payload)) {
      throw new BadRequestException('openingHours muss ein Array sein');
    }
    return payload.map((entry, index) => {
      const weekday = this.requireString(entry.weekday, `openingHours[${index}].weekday`);
      const slots = Array.isArray(entry.slots)
        ? entry.slots.map((slot, slotIndex) => ({
            from: this.requireString(
              slot.from,
              `openingHours[${index}].slots[${slotIndex}].from`,
            ),
            to: this.requireString(
              slot.to,
              `openingHours[${index}].slots[${slotIndex}].to`,
            ),
          }))
        : [];
      const note = entry.note?.trim() || undefined;
      return { weekday, slots, note };
    });
  }

  private validateLinks(
    payload: MunicipalityProfileLink[],
  ): MunicipalityProfileLink[] {
    if (!Array.isArray(payload)) {
      throw new BadRequestException('importantLinks muss ein Array sein');
    }
    return payload.map((entry, index) => ({
      label: this.requireString(entry.label, `importantLinks[${index}].label`),
      url: this.validateUrl(entry.url, `importantLinks[${index}].url`),
    }));
  }

  private validateEmergencyNumbers(
    payload: MunicipalityProfileEmergencyNumber[],
  ): MunicipalityProfileEmergencyNumber[] {
    if (!Array.isArray(payload)) {
      throw new BadRequestException('emergencyNumbers muss ein Array sein');
    }
    return payload.map((entry, index) => ({
      label: this.requireString(
        entry.label,
        `emergencyNumbers[${index}].label`,
      ),
      number: this.requireString(
        entry.number,
        `emergencyNumbers[${index}].number`,
      ),
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
