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
import { MunicipalityEventsService } from './municipality-events.service';
import {
  EventStatus,
  MunicipalityEvent,
  MunicipalityEventInput,
  MunicipalityEventPatch,
} from './municipality-events.types';

@Controller()
export class MunicipalityEventsController {
  constructor(
    private readonly municipalityEventsService: MunicipalityEventsService,
  ) {}

  @Get('api/events')
  @Header('Cache-Control', 'private, max-age=30')
  async getEvents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ): Promise<MunicipalityEvent[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityEventsService.list(tenantId, {
      from: this.parseDate(from, 'from'),
      to: this.parseDate(to, 'to'),
      status: status ? this.parseStatus(status) : undefined,
      limit: limit ? this.parseLimit(limit) : undefined,
    });
  }

  @Get('api/feed/events')
  @Header('Cache-Control', 'private, max-age=30')
  async getEventFeed(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('from') from?: string,
    @Query('weeks') weeks?: string,
    @Query('limit') limit?: string,
  ): Promise<MunicipalityEvent[]> {
    const tenantId = requireTenant(headers);
    const fromDate = this.parseDate(from, 'from') ?? new Date();
    const parsedWeeks = this.parseWeeks(weeks);
    const toDate = new Date(fromDate);
    toDate.setDate(toDate.getDate() + parsedWeeks * 7);
    const parsedLimit = this.parseFeedLimit(limit);
    return this.municipalityEventsService.listFeed(
      tenantId,
      fromDate,
      toDate,
      parsedLimit,
    );
  }

  @Get('api/admin/events')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async getAdminEvents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
  ): Promise<MunicipalityEvent[]> {
    const tenantId = requireTenant(headers);
    return this.municipalityEventsService.list(tenantId, {
      from: this.parseDate(from, 'from'),
      to: this.parseDate(to, 'to'),
      status: status ? this.parseStatus(status) : undefined,
      limit: limit ? this.parseLimit(limit) : undefined,
    });
  }

  @Post('api/admin/events')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async createEvent(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: MunicipalityEventInput,
  ): Promise<MunicipalityEvent> {
    const tenantId = requireTenant(headers);
    const input = this.validateCreate(payload);
    return this.municipalityEventsService.create(tenantId, input);
  }

  @Patch('api/admin/events/:id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async updateEvent(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
    @Body() payload: MunicipalityEventPatch,
  ): Promise<MunicipalityEvent> {
    const tenantId = requireTenant(headers);
    const patch = this.validatePatch(payload);
    return this.municipalityEventsService.update(tenantId, id, patch);
  }

  @Delete('api/admin/events/:id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  @Header('Cache-Control', 'no-store')
  async deleteEvent(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Param('id') id: string,
  ) {
    const tenantId = requireTenant(headers);
    await this.municipalityEventsService.archive(tenantId, id);
    return { ok: true };
  }

  private validateCreate(payload: MunicipalityEventInput) {
    const title = this.requireString(payload.title, 'title');
    const description = this.requireString(payload.description, 'description');
    const location = this.requireString(payload.location, 'location');
    const startAt = this.requireDate(payload.startAt, 'startAt');
    const endAt = payload.endAt ? this.requireDate(payload.endAt, 'endAt') : undefined;

    if (endAt && Date.parse(endAt) < Date.parse(startAt)) {
      throw new BadRequestException('endAt muss nach startAt liegen');
    }

    return {
      title,
      description,
      location,
      startAt,
      endAt,
      status: payload.status ? this.parseStatus(payload.status) : undefined,
    };
  }

  private validatePatch(payload: MunicipalityEventPatch) {
    const patch: MunicipalityEventPatch = {};
    if (payload.title !== undefined) {
      patch.title = this.requireString(payload.title, 'title');
    }
    if (payload.description !== undefined) {
      patch.description = this.requireString(payload.description, 'description');
    }
    if (payload.location !== undefined) {
      patch.location = this.requireString(payload.location, 'location');
    }
    if (payload.startAt !== undefined) {
      patch.startAt = this.requireDate(payload.startAt, 'startAt');
    }
    if (payload.endAt !== undefined) {
      patch.endAt = this.requireDate(payload.endAt, 'endAt');
    }
    if (payload.status !== undefined) {
      patch.status = this.parseStatus(payload.status);
    }

    if (patch.endAt && patch.startAt) {
      if (Date.parse(patch.endAt) < Date.parse(patch.startAt)) {
        throw new BadRequestException('endAt muss nach startAt liegen');
      }
    }

    return patch;
  }

  private parseDate(value: string | undefined, field: string) {
    if (!value) {
      return undefined;
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein gültiger ISO-8601-String sein`);
    }
    return new Date(parsed);
  }

  private requireDate(value: string | undefined, field: string) {
    if (!value) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    const parsed = Date.parse(value);
    if (Number.isNaN(parsed)) {
      throw new BadRequestException(`${field} muss ein gültiger ISO-8601-String sein`);
    }
    return new Date(parsed).toISOString();
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private parseStatus(value: string): EventStatus {
    const normalized = value.trim().toUpperCase() as EventStatus;
    if (!['DRAFT', 'PUBLISHED', 'ARCHIVED'].includes(normalized)) {
      throw new BadRequestException('status ist ungültig');
    }
    return normalized;
  }

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }

  private parsePositiveNumber(value: string, field: string) {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException(`${field} muss eine positive Zahl sein`);
    }
    return parsed;
  }

  private parseWeeks(value: string | undefined): number {
    if (!value) {
      return 4;
    }
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return 4;
    }
    return Math.min(Math.max(parsed, 1), 52);
  }

  private parseFeedLimit(value: string | undefined): number {
    if (!value) {
      return 50;
    }
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return 50;
    }
    return Math.min(Math.max(parsed, 1), 200);
  }
}
