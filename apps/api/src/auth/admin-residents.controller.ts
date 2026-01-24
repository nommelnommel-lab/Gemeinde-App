import {
  BadRequestException,
  Body,
  Controller,
  Header,
  Headers,
  Get,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Logger } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { ResidentsService } from './residents.service';
import { ResidentStatus } from './residents.model';

type ResidentPayload = {
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
};

@Controller('api/admin/residents')
@UseGuards(AdminGuard)
export class AdminResidentsController {
  private readonly logger = new Logger(AdminResidentsController.name);

  constructor(private readonly residentsService: ResidentsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  async createResident(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ResidentPayload,
  ) {
    const tenantId = requireTenant(headers);
    const residentId = await this.residentsService.createResident(
      tenantId,
      payload,
    );

    return { residentId };
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  async listResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') q?: string,
    @Query('limit') limit?: string,
    @Query('postalCode') postalCode?: string,
    @Query('houseNumber') houseNumber?: string,
    @Query('status') status?: string,
  ) {
    const tenantId = requireTenant(headers);
    const resolvedLimit = limit ? Number.parseInt(limit, 10) : undefined;
    const normalizedStatus = status
      ? status.trim().toUpperCase()
      : undefined;
    const statusFilter: ResidentStatus | undefined =
      normalizedStatus === undefined || normalizedStatus === ''
        ? undefined
        : normalizedStatus === 'ACTIVE' || normalizedStatus === 'INACTIVE'
          ? (normalizedStatus as ResidentStatus)
          : (() => {
              throw new BadRequestException('status ist ungültig');
            })();
    return this.residentsService.listResidents(
      tenantId,
      q,
      resolvedLimit,
      postalCode,
      houseNumber,
      statusFilter,
    );
  }

  @Post('bulk')
  @Header('Cache-Control', 'no-store')
  async bulkResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ResidentPayload[],
  ) {
    const tenantId = requireTenant(headers);
    if (!Array.isArray(payload) || payload.length === 0) {
      throw new BadRequestException('payload muss ein Array sein');
    }

    return this.residentsService.bulkCreateResidents(tenantId, payload);
  }

  @Post('import')
  @Header('Cache-Control', 'no-store')
  @UseInterceptors(FileInterceptor('file'))
  async importResidents(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @UploadedFile() file?: { buffer?: Buffer },
  ) {
    const tenantId = requireTenant(headers);
    if (!file?.buffer?.length) {
      throw new BadRequestException('CSV-Datei fehlt');
    }
    const content = file.buffer.toString('utf8');
    const rows = this.parseCsv(content);
    if (rows.length === 0) {
      throw new BadRequestException('CSV ist leer');
    }
    const header = rows[0].map((value) => value.trim().toLowerCase());
    const requiredColumns = [
      'firstname',
      'lastname',
      'postalcode',
      'housenumber',
    ];
    const indexByColumn = new Map<string, number>();
    header.forEach((value, index) => {
      if (!value) {
        return;
      }
      if (!indexByColumn.has(value)) {
        indexByColumn.set(value, index);
      }
    });
    for (const column of requiredColumns) {
      if (!indexByColumn.has(column)) {
        throw new BadRequestException(`CSV fehlt Spalte ${column}`);
      }
    }

    let created = 0;
    let skipped = 0;
    const errors: Array<{ row: number; message: string }> = [];

    for (let rowIndex = 1; rowIndex < rows.length; rowIndex += 1) {
      const row = rows[rowIndex];
      if (row.every((value) => value.trim() === '')) {
        continue;
      }
      try {
        const payload = {
          firstName: this.getRowValue(row, indexByColumn, 'firstname'),
          lastName: this.getRowValue(row, indexByColumn, 'lastname'),
          postalCode: this.getRowValue(row, indexByColumn, 'postalcode'),
          houseNumber: this.getRowValue(row, indexByColumn, 'housenumber'),
        };
        const normalized = this.residentsService.normalizeResidentInput(payload);
        const existing = await this.residentsService.findByIdentity(
          tenantId,
          normalized,
        );
        if (existing) {
          skipped += 1;
          continue;
        }
        await this.residentsService.createResident(tenantId, normalized);
        created += 1;
      } catch (error) {
        errors.push({
          row: rowIndex + 1,
          message: error instanceof Error ? error.message : 'Unbekannter Fehler',
        });
      }
    }

    const summary = {
      created,
      skipped,
      failed: errors.length,
      errors,
    };

    if (process.env.NODE_ENV !== 'production') {
      this.logger.log('[admin_resident_import]', {
        tenantId,
        created,
        skipped,
        failed: errors.length,
      });
    }

    return summary;
  }

  private parseCsv(content: string) {
    const rows: string[][] = [];
    const lines = content.split(/\r?\n/);
    for (const line of lines) {
      if (line.trim() === '') {
        continue;
      }
      rows.push(this.parseCsvLine(line));
    }
    return rows;
  }

  private parseCsvLine(line: string) {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i += 1) {
      const char = line[i];
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        result.push(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.push(current);
    return result;
  }

  private getRowValue(
    row: string[],
    indexByColumn: Map<string, number>,
    column: string,
  ) {
    const index = indexByColumn.get(column);
    if (index === undefined) {
      return '';
    }
    return row[index] ?? '';
  }
}
