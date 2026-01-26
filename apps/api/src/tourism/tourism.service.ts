import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import {
  TourismItemEntity,
  TourismItemStatus,
  TourismItemType,
} from './tourism.types';

type TourismInput = {
  tenantId: string;
  type: TourismItemType;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
  status?: TourismItemStatus;
};

type TourismPatch = Partial<Omit<TourismInput, 'tenantId'>> & {
  status?: TourismItemStatus;
};

type ListOptions = {
  type?: TourismItemType;
  limit?: number;
  offset?: number;
  query?: string;
  status?: TourismItemStatus;
  includeHidden?: boolean;
};

type SeedInput = {
  type: TourismItemType;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
};

@Injectable()
export class TourismService {
  private readonly repository = new TenantFileRepository<TourismItemEntity>(
    'tourism-items',
  );
  private static readonly DEFAULT_LIMIT = 20;
  private static readonly MAX_LIMIT = 50;

  async list(
    tenantId: string,
    options: ListOptions = {},
  ): Promise<TourismItemEntity[]> {
    const items = await this.repository.getAll(tenantId);
    const query = options.query?.trim().toLowerCase();
    const statusFilter = this.resolveStatusFilter(options);

    const filtered = items.filter((item) => {
      if (!this.matchesVisibility(item, options, statusFilter)) {
        return false;
      }
      if (options.type && item.type !== options.type) {
        return false;
      }
      if (query) {
        const haystack = `${item.title} ${item.body}`.toLowerCase();
        if (!haystack.includes(query)) {
          return false;
        }
      }
      return true;
    });

    const sorted = filtered.sort(
      (a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt),
    );

    return this.applyPagination(sorted, options);
  }

  async getById(
    tenantId: string,
    id: string,
    options: { includeHidden?: boolean } = {},
  ): Promise<TourismItemEntity> {
    const items = await this.repository.getAll(tenantId);
    const item = items.find((entry) => entry.id === id);
    if (!item) {
      throw new NotFoundException('Tourismus-Eintrag nicht gefunden');
    }
    const statusFilter = this.resolveStatusFilter(options);
    if (!this.matchesVisibility(item, options, statusFilter)) {
      throw new NotFoundException('Tourismus-Eintrag nicht gefunden');
    }
    return item;
  }

  async create(input: TourismInput): Promise<TourismItemEntity> {
    const items = await this.repository.getAll(input.tenantId);
    const now = new Date().toISOString();
    const item: TourismItemEntity = {
      id: randomUUID(),
      tenantId: input.tenantId,
      type: input.type,
      title: input.title,
      body: input.body,
      metadata: input.metadata ?? {},
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };

    items.push(item);
    await this.repository.setAll(input.tenantId, items);
    return item;
  }

  async update(
    tenantId: string,
    id: string,
    patch: TourismPatch,
  ): Promise<TourismItemEntity> {
    const items = await this.repository.getAll(tenantId);
    const index = items.findIndex((entry) => entry.id === id);
    if (index === -1) {
      throw new NotFoundException('Tourismus-Eintrag nicht gefunden');
    }

    const base = items[index];
    const updated: TourismItemEntity = {
      ...base,
      type: patch.type ?? base.type,
      title: patch.title ?? base.title,
      body: patch.body ?? base.body,
      metadata: patch.metadata ?? base.metadata ?? {},
      status: patch.status ?? base.status,
      updatedAt: new Date().toISOString(),
    };

    items[index] = updated;
    await this.repository.setAll(tenantId, items);
    return updated;
  }

  async hide(tenantId: string, id: string): Promise<TourismItemEntity> {
    return this.update(tenantId, id, { status: 'HIDDEN' });
  }

  async seedDemo(
    tenantId: string,
    seedItems: SeedInput[],
  ): Promise<void> {
    const items = await this.repository.getAll(tenantId);
    const retained = items.filter(
      (item) => item.metadata?.demoSeed !== true,
    );
    const now = new Date().toISOString();
    const seeded = seedItems.map((seed) => ({
      id: randomUUID(),
      tenantId,
      type: seed.type,
      title: seed.title,
      body: seed.body,
      metadata: {
        ...(seed.metadata ?? {}),
        demoSeed: true,
      },
      status: 'PUBLISHED' as TourismItemStatus,
      createdAt: now,
      updatedAt: now,
    }));

    await this.repository.setAll(tenantId, [...retained, ...seeded]);
  }

  private resolveStatusFilter(options: {
    status?: TourismItemStatus;
    includeHidden?: boolean;
  }): TourismItemStatus | undefined {
    if (options.status) {
      return options.status;
    }
    if (options.includeHidden) {
      return undefined;
    }
    return 'PUBLISHED';
  }

  private matchesVisibility(
    item: TourismItemEntity,
    options: { includeHidden?: boolean },
    statusFilter?: TourismItemStatus,
  ) {
    if (!statusFilter) {
      return true;
    }
    return (item.status ?? 'PUBLISHED') === statusFilter;
  }

  private applyPagination(
    items: TourismItemEntity[],
    options: { limit?: number; offset?: number },
  ) {
    const limit = Math.min(
      Math.max(options.limit ?? TourismService.DEFAULT_LIMIT, 1),
      TourismService.MAX_LIMIT,
    );
    const offset = Math.max(options.offset ?? 0, 0);
    return items.slice(offset, offset + limit);
  }
}
