import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Headers,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { Roles } from '../../auth/roles.decorator';
import { RolesGuard } from '../../auth/roles.guard';
import { UserRole } from '../../auth/user-roles';
import { requireTenant } from '../../tenant/tenant-auth';
import { MunicipalityClubsService } from './municipality-clubs.service';
import {
  ClubStatus,
  MunicipalityClub,
  MunicipalityClubInput,
  MunicipalityClubPatch,
} from './municipality-clubs.types';

@Controller()
export class MunicipalityClubsController {
  constructor(private readonly municipalityClubsService: MunicipalityClubsService) {}

  @Get('api/clubs')
  @Header('Cache-Control', 'private, max-age=30')
  async getClubs(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') query?: string,
    @Query('status') status?: string,
  ): Promise<MunicipalityClub[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityClubsService.list(tenantId, {
      query: query?.trim() || undefined,
      status: status ? this.parseStatus(status) : undefined,
    });
  }

  @Get('api/clubs/:id')
  @Header('Cache-Control', 'private, max-age=30')
  async getClub(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ): Promise<MunicipalityClub> {
    const tenantId = requireTenant(headers);
    return this.municipalityClubsService.getById(tenantId, id);
  }

  @Get('api/admin/clubs')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async getAdminClubs(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') query?: string,
    @Query('status') status?: string,
  ): Promise<MunicipalityClub[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityClubsService.list(tenantId, {
      query: query?.trim() || undefined,
      status: status ? this.parseStatus(status) : undefined,
    });
  }

  @Post('api/admin/clubs')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async createClub(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityClubInput,
  ): Promise<MunicipalityClub> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.municipalityClubsService.create(tenantId, input);
  }

  @Patch('api/admin/clubs/:id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async updateClub(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: MunicipalityClubPatch,
  ): Promise<MunicipalityClub> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.municipalityClubsService.update(tenantId, id, patch);
  }

  @Delete('api/admin/clubs/:id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async deleteClub(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    await this.municipalityClubsService.archive(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: MunicipalityClubInput) {
    const name = this.requireString(payload.name, 'name');
    const description = this.requireString(payload.description, 'description');
    const contactName = payload.contactName?.trim() || undefined;
    const email = payload.email?.trim() || undefined;
    const phone = payload.phone?.trim() || undefined;
    const website = payload.website?.trim() || undefined;
    const status = payload.status ? this.parseStatus(payload.status) : undefined;
    return {
      name,
      description,
      contactName,
      email,
      phone,
      website,
      status,
    };
  }

  private validatePatch(payload: MunicipalityClubPatch) {
    const patch: MunicipalityClubPatch = {};
    if (payload.name !== undefined) {
      patch.name = this.requireString(payload.name, 'name');
    }
    if (payload.description !== undefined) {
      patch.description = this.requireString(payload.description, 'description');
    }
    if (payload.contactName !== undefined) {
      patch.contactName = payload.contactName.trim() || undefined;
    }
    if (payload.email !== undefined) {
      patch.email = payload.email.trim() || undefined;
    }
    if (payload.phone !== undefined) {
      patch.phone = payload.phone.trim() || undefined;
    }
    if (payload.website !== undefined) {
      patch.website = payload.website.trim() || undefined;
    }
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }
    return patch;
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private parseStatus(value: string): ClubStatus {
    const normalized = value.trim().toUpperCase() as ClubStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }
}
