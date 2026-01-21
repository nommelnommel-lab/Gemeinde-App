import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import path from 'path';
import { EventEntity } from './events.types';

type EventInput = {
  title: string;
  description: string;
  date: string;
  location: string;
};

@Injectable()
export class EventsService implements OnModuleInit {
  private events: EventEntity[] = [];
  private readonly dataFilePath = path.join(
    process.cwd(),
    'data',
    'events.json',
  );

  async onModuleInit() {
    await this.ensureDataFile();
    await this.loadEvents();
  }

  async getAll(): Promise<EventEntity[]> {
    return [...this.events].sort(
      (a, b) => Date.parse(a.date) - Date.parse(b.date),
    );
  }

  async getById(id: string): Promise<EventEntity> {
    const event = this.events.find((item) => item.id === id);
    if (!event) {
      throw new NotFoundException('Event nicht gefunden');
    }
    return event;
  }

  async create(input: EventInput): Promise<EventEntity> {
    const now = new Date().toISOString();
    const event: EventEntity = {
      id: randomUUID(),
      title: input.title,
      description: input.description,
      date: input.date,
      location: input.location,
      createdAt: now,
      updatedAt: now,
    };

    this.events.push(event);
    await this.persist();
    return event;
  }

  async update(id: string, input: EventInput): Promise<EventEntity> {
    const index = this.events.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Event nicht gefunden');
    }

    const updated: EventEntity = {
      ...this.events[index],
      title: input.title,
      description: input.description,
      date: input.date,
      location: input.location,
      updatedAt: new Date().toISOString(),
    };

    this.events[index] = updated;
    await this.persist();
    return updated;
  }

  async remove(id: string): Promise<void> {
    const index = this.events.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Event nicht gefunden');
    }

    this.events.splice(index, 1);
    await this.persist();
  }

  private async ensureDataFile() {
    const dataDir = path.dirname(this.dataFilePath);
    await fs.mkdir(dataDir, { recursive: true });
    try {
      await fs.access(this.dataFilePath);
    } catch {
      const seed = this.createSeedEvents();
      await this.writeFileAtomic(seed);
    }
  }

  private async loadEvents() {
    const file = await fs.readFile(this.dataFilePath, 'utf8');
    const parsed = JSON.parse(file);
    this.events = Array.isArray(parsed) ? (parsed as EventEntity[]) : [];
  }

  private async persist() {
    await this.writeFileAtomic(this.events);
  }

  private async writeFileAtomic(data: EventEntity[]) {
    const tempPath = `${this.dataFilePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, this.dataFilePath);
  }

  private createSeedEvents(): EventEntity[] {
    const now = new Date().toISOString();
    return [
      {
        id: randomUUID(),
        title: 'Gemeindefest',
        description: 'Ein gemeinsamer Nachmittag mit Musik und Buffet.',
        date: '2024-09-14T14:00:00.000Z',
        location: 'Gemeindezentrum',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Jugendabend',
        description: 'Spiele, Snacks und Austausch für Jugendliche.',
        date: '2024-09-20T17:30:00.000Z',
        location: 'Jugendraum',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Flohmarkt',
        description: 'Stöbern, verkaufen und Kaffee trinken.',
        date: '2024-10-05T09:00:00.000Z',
        location: 'Kirchplatz',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Chorprobe',
        description: 'Offene Probe für alle, die mitsingen möchten.',
        date: '2024-10-11T18:00:00.000Z',
        location: 'Proberaum',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Vortrag: Nachhaltig leben',
        description: 'Impulse und Diskussion rund um Nachhaltigkeit.',
        date: '2024-10-18T18:30:00.000Z',
        location: 'Gemeindesaal',
        createdAt: now,
        updatedAt: now,
      },
    ];
  }
}
