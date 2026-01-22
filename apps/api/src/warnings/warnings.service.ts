import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';
import { WarningEntity, WarningSeverity } from './warnings.types';

type WarningInput = {
  title: string;
  description: string;
  severity: WarningSeverity;
  validUntil: string | null;
};

@Injectable()
export class WarningsService implements OnModuleInit {
  private warnings: WarningEntity[] = [];
  private readonly dataFilePath = join(
    process.cwd(),
    'data',
    'warnings.json',
  );

  async onModuleInit() {
    await this.ensureDataFile();
    await this.loadWarnings();
  }

  async getAll(): Promise<WarningEntity[]> {
    return [...this.warnings].sort((a, b) =>
      this.getSortTime(b) - this.getSortTime(a),
    );
  }

  async getById(id: string): Promise<WarningEntity> {
    const warning = this.warnings.find((item) => item.id === id);
    if (!warning) {
      throw new NotFoundException('Warnung nicht gefunden');
    }
    return warning;
  }

  async create(input: WarningInput): Promise<WarningEntity> {
    const now = new Date().toISOString();
    const warning: WarningEntity = {
      id: randomUUID(),
      title: input.title,
      description: input.description,
      severity: input.severity,
      publishedAt: now,
      validUntil: input.validUntil,
      createdAt: now,
      updatedAt: now,
    };

    this.warnings.push(warning);
    await this.persist();
    return warning;
  }

  async update(id: string, input: WarningInput): Promise<WarningEntity> {
    const index = this.warnings.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Warnung nicht gefunden');
    }

    const updated: WarningEntity = {
      ...this.warnings[index],
      title: input.title,
      description: input.description,
      severity: input.severity,
      validUntil: input.validUntil,
      updatedAt: new Date().toISOString(),
    };

    this.warnings[index] = updated;
    await this.persist();
    return updated;
  }

  async remove(id: string): Promise<void> {
    const index = this.warnings.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Warnung nicht gefunden');
    }

    this.warnings.splice(index, 1);
    await this.persist();
  }

  private getSortTime(warning: WarningEntity) {
    return Date.parse(warning.publishedAt || warning.createdAt);
  }

  private async ensureDataFile() {
    const dataDir = dirname(this.dataFilePath);
    await fs.mkdir(dataDir, { recursive: true });
    try {
      await fs.access(this.dataFilePath);
    } catch {
      const seed = this.createSeedWarnings();
      await this.writeFileAtomic(seed);
    }
  }

  private async loadWarnings() {
    const file = await fs.readFile(this.dataFilePath, 'utf8');
    const parsed = JSON.parse(file);
    this.warnings = Array.isArray(parsed) ? (parsed as WarningEntity[]) : [];
  }

  private async persist() {
    await this.writeFileAtomic(this.warnings);
  }

  private async writeFileAtomic(data: WarningEntity[]) {
    const tempPath = `${this.dataFilePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, this.dataFilePath);
  }

  private createSeedWarnings(): WarningEntity[] {
    const now = new Date().toISOString();
    return [
      {
        id: randomUUID(),
        title: 'Wartungsarbeiten',
        description:
          'Am Sonntag kann es zwischen 9 und 11 Uhr zu kurzen Ausfällen kommen.',
        severity: 'minor',
        publishedAt: now,
        validUntil: '2024-12-31T22:00:00.000Z',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Sturmwarnung',
        description:
          'Bitte meiden Sie die Parkanlage und sichern Sie lose Gegenstände.',
        severity: 'major',
        publishedAt: now,
        validUntil: null,
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Infoservice',
        description: 'Neue Öffnungszeiten ab dem kommenden Montag.',
        severity: 'info',
        publishedAt: now,
        validUntil: null,
        createdAt: now,
        updatedAt: now,
      },
    ];
  }
}
