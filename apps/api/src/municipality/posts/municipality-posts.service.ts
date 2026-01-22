import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  MunicipalityPost,
  MunicipalityPostInput,
  MunicipalityPostPatch,
  PostPriority,
  PostStatus,
  PostType,
} from './municipality-posts.types';

@Injectable()
export class MunicipalityPostsService {
  private readonly repository = new TenantFileRepository<MunicipalityPost>(
    'posts',
    (tenantId) => this.createSeedPosts(tenantId),
  );

  async list(
    tenantId: string,
    options: {
      type?: PostType;
      from?: Date;
      to?: Date;
      status?: PostStatus;
      limit?: number;
      now?: Date;
    },
  ): Promise<MunicipalityPost[]> {
    const status = options.status ?? 'PUBLISHED';
    const now = options.now ?? new Date();
    const posts = await this.repository.getAll(tenantId);
    const filtered = posts.filter((post) => {
      if (post.status !== status) {
        return false;
      }
      if (options.type && post.type !== options.type) {
        return false;
      }
      const publishedAt = Date.parse(post.publishedAt);
      if (options.from && publishedAt < options.from.getTime()) {
        return false;
      }
      if (options.to && publishedAt > options.to.getTime()) {
        return false;
      }
      if (post.type === 'WARNING' && post.endsAt) {
        if (Date.parse(post.endsAt) < now.getTime()) {
          return false;
        }
      }
      return true;
    });

    const warnings = filtered
      .filter((post) => post.type === 'WARNING')
      .sort((a, b) => {
        const priorityScore = (priority?: PostPriority) => {
          switch (priority) {
            case 'HIGH':
              return 3;
            case 'MEDIUM':
              return 2;
            case 'LOW':
              return 1;
            default:
              return 0;
          }
        };
        const priorityDiff =
          priorityScore(b.priority) - priorityScore(a.priority);
        if (priorityDiff !== 0) {
          return priorityDiff;
        }
        return Date.parse(b.publishedAt) - Date.parse(a.publishedAt);
      });

    const news = filtered
      .filter((post) => post.type === 'NEWS')
      .sort(
        (a, b) => Date.parse(b.publishedAt) - Date.parse(a.publishedAt),
      );

    const combined = [...warnings, ...news];
    if (options.limit) {
      return combined.slice(0, options.limit);
    }
    return combined;
  }

  async listFeed(
    tenantId: string,
    from: Date,
    to: Date,
  ): Promise<MunicipalityPost[]> {
    return this.list(tenantId, {
      from,
      to,
      status: 'PUBLISHED',
      now: to,
    });
  }

  async create(
    tenantId: string,
    input: MunicipalityPostInput,
  ): Promise<MunicipalityPost> {
    const posts = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const post: MunicipalityPost = {
      id: randomUUID(),
      tenantId,
      type: input.type,
      title: input.title,
      body: input.body,
      priority: input.priority,
      publishedAt: input.publishedAt,
      endsAt: input.endsAt,
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };
    posts.push(post);
    await this.repository.setAll(tenantId, posts);
    return post;
  }

  async update(
    tenantId: string,
    id: string,
    patch: MunicipalityPostPatch,
  ): Promise<MunicipalityPost> {
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((post) => post.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }

    const updated: MunicipalityPost = {
      ...posts[index],
      type: patch.type ?? posts[index].type,
      title: patch.title ?? posts[index].title,
      body: patch.body ?? posts[index].body,
      priority: patch.priority ?? posts[index].priority,
      publishedAt: patch.publishedAt ?? posts[index].publishedAt,
      endsAt: patch.endsAt ?? posts[index].endsAt,
      status: patch.status ?? posts[index].status,
      updatedAt: new Date().toISOString(),
    };

    posts[index] = updated;
    await this.repository.setAll(tenantId, posts);
    return updated;
  }

  async archive(tenantId: string, id: string): Promise<void> {
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((post) => post.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }

    posts[index] = {
      ...posts[index],
      status: 'ARCHIVED',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, posts);
  }

  private createSeedPosts(tenantId: string): MunicipalityPost[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date();
    const daysAgo = (days: number) => {
      const date = new Date(now);
      date.setDate(date.getDate() - days);
      return date;
    };

    const daysFromNow = (days: number) => {
      const date = new Date(now);
      date.setDate(date.getDate() + days);
      return date;
    };

    const seedTimestamp = now.toISOString();

    return [
      {
        id: randomUUID(),
        tenantId,
        type: 'NEWS',
        title: 'Rathaus verlängert Öffnungszeiten',
        body: 'Das Rathaus öffnet donnerstags bis 18:00 Uhr.',
        publishedAt: daysAgo(2).toISOString(),
        status: 'PUBLISHED',
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
      },
      {
        id: randomUUID(),
        tenantId,
        type: 'NEWS',
        title: 'Neue Radabstellanlage am Bahnhof',
        body: '20 neue Stellplätze stehen ab sofort zur Verfügung.',
        publishedAt: daysAgo(7).toISOString(),
        status: 'PUBLISHED',
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
      },
      {
        id: randomUUID(),
        tenantId,
        type: 'NEWS',
        title: 'Anmeldung Ferienprogramm gestartet',
        body: 'Ab sofort sind Anmeldungen im Bürgerbüro möglich.',
        publishedAt: daysAgo(12).toISOString(),
        status: 'PUBLISHED',
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
      },
      {
        id: randomUUID(),
        tenantId,
        type: 'WARNING',
        title: 'Wasserrohrbruch in der Marktstraße',
        body: 'Bitte meiden Sie den Bereich, Reparaturen laufen.',
        priority: 'HIGH',
        publishedAt: daysAgo(1).toISOString(),
        endsAt: daysFromNow(2).toISOString(),
        status: 'PUBLISHED',
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
      },
      {
        id: randomUUID(),
        tenantId,
        type: 'WARNING',
        title: 'Bauarbeiten abgeschlossen',
        body: 'Die Sperrung der Rhönstraße ist aufgehoben.',
        priority: 'LOW',
        publishedAt: daysAgo(40).toISOString(),
        endsAt: daysAgo(10).toISOString(),
        status: 'PUBLISHED',
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
      },
    ];
  }
}
