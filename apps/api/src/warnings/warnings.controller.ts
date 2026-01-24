import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/user-roles';
import { WarningsService } from './warnings.service';
import { WarningEntity, WarningSeverity } from './warnings.types';

type WarningPayload = {
  title?: string;
  description?: string;
  severity?: string;
  validUntil?: string | null;
};

@Controller('warnings')
export class WarningsController {
  private readonly allowedSeverities: WarningSeverity[] = [
    'info',
    'minor',
    'major',
    'critical',
  ];

  constructor(private readonly warningsService: WarningsService) {}

  @Get()
  async getWarnings(): Promise<WarningEntity[]> {
    return this.warningsService.getAll();
  }

  @Get(':id')
  async getWarning(@Param('id') id: string): Promise<WarningEntity> {
    return this.warningsService.getById(id);
  }

  @Post()
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async createWarning(
    @Body() payload: WarningPayload,
  ): Promise<WarningEntity> {
    const data = this.validatePayload(payload);
    return this.warningsService.create(data);
  }

  @Put(':id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async updateWarning(
    @Param('id') id: string,
    @Body() payload: WarningPayload,
  ): Promise<WarningEntity> {
    const data = this.validatePayload(payload);
    return this.warningsService.update(id, data);
  }

  @Delete(':id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async deleteWarning(
    @Param('id') id: string,
  ) {
    await this.warningsService.remove(id);
    return { ok: true };
  }

  private validatePayload(payload: WarningPayload) {
    const title = this.requireString(payload.title, 'title');
    const description = this.requireString(payload.description, 'description');
    const severity = this.requireSeverity(payload.severity);
    const validUntil = this.parseOptionalDate(payload.validUntil, 'validUntil');

    return { title, description, severity, validUntil };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private requireSeverity(value: string | undefined): WarningSeverity {
    const severity = this.requireString(value, 'severity') as WarningSeverity;
    if (!this.allowedSeverities.includes(severity)) {
      throw new BadRequestException(
        `severity muss einer der Werte ${this.allowedSeverities.join(', ')} sein`,
      );
    }
    return severity;
  }

  private parseOptionalDate(
    value: string | null | undefined,
    field: string,
  ): string | null {
    if (value === null || value === undefined) {
      return null;
    }

    if (typeof value !== 'string') {
      throw new BadRequestException(`${field} muss ein ISO-8601-String sein`);
    }

    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return null;
    }

    if (Number.isNaN(Date.parse(trimmed))) {
      throw new BadRequestException(
        `${field} muss ein gültiger ISO-8601-String sein`,
      );
    }

    return trimmed;
  }

}
