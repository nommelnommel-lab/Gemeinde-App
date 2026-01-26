import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  EventStatus,
  MunicipalityEvent,
  MunicipalityEventInput,
  MunicipalityEventPatch,
} from './municipality-events.types';

@Injectable()
export class MunicipalityEventsService {
  private readonly repository = new TenantFileRepository<MunicipalityEvent>(
    'events',
    (tenantId) => this.createSeedEvents(tenantId),
  );

  async list(
    tenantId: string,
    options: {
      from?: Date;
      to?: Date;
      status?: EventStatus;
      limit?: number;
    },
  ): Promise<MunicipalityEvent[]> {
    const status = options.status ?? 'PUBLISHED';
    const events = await this.repository.getAll(tenantId);
    const filtered = events.filter((event) => {
      if (event.status !== status) {
        return false;
      }
      const start = Date.parse(event.startAt);
      if (options.from && start < options.from.getTime()) {
        return false;
      }
      if (options.to && start > options.to.getTime()) {
        return false;
      }
      return true;
    });

    const sorted = filtered.sort(
      (a, b) => Date.parse(a.startAt) - Date.parse(b.startAt),
    );

    if (options.limit) {
      return sorted.slice(0, options.limit);
    }

    return sorted;
  }

  async listFeed(
    tenantId: string,
    from: Date,
    to: Date,
    limit: number,
  ): Promise<MunicipalityEvent[]> {
    const events = await this.list(tenantId, {
      from,
      to,
      status: 'PUBLISHED',
    });
    const filtered = events.filter(
      (event) => Date.parse(event.startAt) < to.getTime(),
    );
    return filtered.slice(0, limit);
  }

  async create(
    tenantId: string,
    input: MunicipalityEventInput,
  ): Promise<MunicipalityEvent> {
    const events = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const event: MunicipalityEvent = {
      id: randomUUID(),
      tenantId,
      title: input.title,
      description: input.description,
      location: input.location,
      category: input.category,
      startAt: input.startAt,
      endAt: input.endAt,
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };
    events.push(event);
    await this.repository.setAll(tenantId, events);
    return event;
  }

  async update(
    tenantId: string,
    id: string,
    patch: MunicipalityEventPatch,
  ): Promise<MunicipalityEvent> {
    const events = await this.repository.getAll(tenantId);
    const index = events.findIndex((event) => event.id === id);
    if (index === -1) {
      throw new NotFoundException('Event nicht gefunden');
    }

    const updated: MunicipalityEvent = {
      ...events[index],
      title: patch.title ?? events[index].title,
      description: patch.description ?? events[index].description,
      location: patch.location ?? events[index].location,
      category: patch.category ?? events[index].category,
      startAt: patch.startAt ?? events[index].startAt,
      endAt: patch.endAt ?? events[index].endAt,
      status: patch.status ?? events[index].status,
      updatedAt: new Date().toISOString(),
    };

    events[index] = updated;
    await this.repository.setAll(tenantId, events);
    return updated;
  }

  async archive(tenantId: string, id: string): Promise<void> {
    const events = await this.repository.getAll(tenantId);
    const index = events.findIndex((event) => event.id === id);
    if (index === -1) {
      throw new NotFoundException('Event nicht gefunden');
    }

    events[index] = {
      ...events[index],
      status: 'ARCHIVED',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, events);
  }

  private createSeedEvents(tenantId: string): MunicipalityEvent[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date();
    const addDays = (days: number) => {
      const date = new Date(now);
      date.setDate(date.getDate() + days);
      return date;
    };

    const createEvent = (
      offsetDays: number,
      title: string,
      location: string,
    ): MunicipalityEvent => {
      const start = addDays(offsetDays);
      const end = new Date(start);
      end.setHours(start.getHours() + 2);
      const timestamp = now.toISOString();
      return {
        id: randomUUID(),
        tenantId,
        title,
        description: `${title} in der Gemeinde Hilders.`,
        location,
        category: 'Gemeinde',
        startAt: start.toISOString(),
        endAt: end.toISOString(),
        status: 'PUBLISHED',
        createdAt: timestamp,
        updatedAt: timestamp,
      };
    };

    return [
      createEvent(2, 'Familientag am Marktplatz', 'Marktplatz'),
      createEvent(5, 'Bürgersprechstunde', 'Rathaus'),
      createEvent(8, 'Wanderung zur Milseburg', 'Tourist-Info'),
      createEvent(12, 'Konzert im Schlosspark', 'Schlosspark'),
      createEvent(16, 'Seniorencafé', 'Bürgerhaus'),
      createEvent(20, 'Kinoabend im Bürgerhaus', 'Bürgerhaus'),
    ];
  }
}
