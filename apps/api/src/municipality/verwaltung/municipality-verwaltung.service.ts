import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  VerwaltungItem,
  VerwaltungItemInput,
  VerwaltungItemKind,
  VerwaltungItemPatch,
  VerwaltungItemStatus,
} from './municipality-verwaltung.types';

type ListOptions = {
  kind?: VerwaltungItemKind;
  category?: string;
  query?: string;
  status?: VerwaltungItemStatus;
  limit?: number;
  offset?: number;
};

@Injectable()
export class MunicipalityVerwaltungService {
  private readonly repository = new TenantFileRepository<VerwaltungItem>(
    'verwaltung-items',
  );

  async list(
    tenantId: string,
    options: ListOptions,
  ): Promise<VerwaltungItem[]> {
    const items = await this.repository.getAll(tenantId);
    const filtered = this.applyFilters(items, options);
    return this.applyPagination(filtered, options);
  }

  async getById(
    tenantId: string,
    id: string,
    options?: { status?: VerwaltungItemStatus },
  ): Promise<VerwaltungItem> {
    const items = await this.repository.getAll(tenantId);
    const item = items.find((entry) => entry.id === id);
    if (!item || (options?.status && item.status !== options.status)) {
      throw new NotFoundException('Verwaltungseintrag nicht gefunden');
    }
    return item;
  }

  async create(
    tenantId: string,
    input: VerwaltungItemInput,
  ): Promise<VerwaltungItem> {
    const items = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const item: VerwaltungItem = {
      id: randomUUID(),
      tenantId,
      kind: input.kind,
      category: input.category,
      title: input.title,
      description: input.description ?? null,
      url: input.url,
      tags: input.tags ?? [],
      status: input.status ?? 'PUBLISHED',
      sortOrder: input.sortOrder ?? 0,
      metadata: input.metadata,
      createdAt: now,
      updatedAt: now,
    };
    items.push(item);
    await this.repository.setAll(tenantId, items);
    return item;
  }

  async update(
    tenantId: string,
    id: string,
    patch: VerwaltungItemPatch,
  ): Promise<VerwaltungItem> {
    const items = await this.repository.getAll(tenantId);
    const index = items.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Verwaltungseintrag nicht gefunden');
    }
    const now = new Date().toISOString();
    const updated: VerwaltungItem = {
      ...items[index],
      ...patch,
      description:
        patch.description === undefined
          ? items[index].description
          : patch.description,
      tags: patch.tags ?? items[index].tags,
      status: patch.status ?? items[index].status,
      sortOrder: patch.sortOrder ?? items[index].sortOrder,
      metadata: patch.metadata ?? items[index].metadata,
      updatedAt: now,
    };
    items[index] = updated;
    await this.repository.setAll(tenantId, items);
    return updated;
  }

  async hide(tenantId: string, id: string): Promise<void> {
    const items = await this.repository.getAll(tenantId);
    const index = items.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Verwaltungseintrag nicht gefunden');
    }
    items[index] = {
      ...items[index],
      status: 'HIDDEN',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, items);
  }

  private applyFilters(items: VerwaltungItem[], options: ListOptions) {
    const normalizedCategory = options.category?.toLowerCase();
    const normalizedQuery = options.query?.toLowerCase();
    return items
      .filter((item) => (options.kind ? item.kind === options.kind : true))
      .filter((item) =>
        normalizedCategory
          ? item.category.toLowerCase() === normalizedCategory
          : true,
      )
      .filter((item) =>
        options.status ? item.status === options.status : true,
      )
      .filter((item) => {
        if (!normalizedQuery) {
          return true;
        }
        const haystack = [
          item.title,
          item.description ?? '',
          item.category,
          item.tags.join(' '),
        ]
          .join(' ')
          .toLowerCase();
        return haystack.includes(normalizedQuery);
      })
      .sort((a, b) => {
        if (a.sortOrder !== b.sortOrder) {
          return a.sortOrder - b.sortOrder;
        }
        return a.title.localeCompare(b.title, 'de');
      });
  }

  private applyPagination(items: VerwaltungItem[], options: ListOptions) {
    const offset = options.offset ?? 0;
    const limit = options.limit ?? items.length;
    return items.slice(offset, offset + limit);
  }
}
