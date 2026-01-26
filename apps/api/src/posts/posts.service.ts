import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../municipality/storage/tenant-file.repository';
import { PostEntity, PostReport, PostStatus, PostType } from './posts.types';

type PostInput = {
  tenantId: string;
  type: PostType;
  title: string;
  body: string;
  authorUserId?: string;
  category?: PostEntity['category'];
  metadata?: Record<string, unknown>;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
  status?: PostStatus;
};

type PostPatch = Partial<Omit<PostInput, 'tenantId' | 'authorUserId'>> & {
  status?: PostStatus;
  metadata?: Record<string, unknown>;
  hiddenAt?: string;
  hiddenReason?: string;
};

type ListOptions = {
  type?: PostType;
  limit?: number;
  offset?: number;
  query?: string;
  status?: PostStatus;
  includeHidden?: boolean;
  viewerUserId?: string;
  reportedOnly?: boolean;
};

@Injectable()
export class PostsService {
  private readonly repository = new TenantFileRepository<PostEntity>(
    'citizen-posts',
  );
  private readonly reportRepository = new TenantFileRepository<PostReport>(
    'post-reports',
  );
  private static readonly DEFAULT_LIMIT = 20;
  private static readonly MAX_LIMIT = 50;

  async list(
    tenantId: string,
    options: ListOptions = {},
  ): Promise<PostEntity[]> {
    const posts = await this.repository.getAll(tenantId);
    const normalized = posts.map((post) => this.normalizePost(tenantId, post));
    const statusFilter = this.resolveStatusFilter(options);
    const query = options.query?.trim().toLowerCase();

    const filtered = normalized.filter((post) => {
      if (!this.matchesVisibility(post, options, statusFilter)) {
        return false;
      }
      if (options.type && post.type !== options.type) {
        return false;
      }
      if (query) {
        const haystack = `${post.title} ${post.body}`.toLowerCase();
        if (!haystack.includes(query)) {
          return false;
        }
      }
      return true;
    });

    const sorted = filtered.sort(
      (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
    );
    return this.applyPagination(sorted, options);
  }

  async getById(
    tenantId: string,
    id: string,
    options: { includeHidden?: boolean; viewerUserId?: string } = {},
  ): Promise<PostEntity> {
    const posts = await this.repository.getAll(tenantId);
    const post = posts.find((item) => item.id === id);
    if (!post) {
      throw new NotFoundException('Post nicht gefunden');
    }
    const normalized = this.normalizePost(tenantId, post);
    const statusFilter = this.resolveStatusFilter(options);
    if (!this.matchesVisibility(normalized, options, statusFilter)) {
      throw new NotFoundException('Post nicht gefunden');
    }
    return normalized;
  }

  async create(input: PostInput): Promise<PostEntity> {
    const posts = await this.repository.getAll(input.tenantId);
    const now = new Date().toISOString();
    const post: PostEntity = {
      id: randomUUID(),
      tenantId: input.tenantId,
      type: input.type,
      category: input.category,
      authorUserId: input.authorUserId,
      title: input.title,
      body: input.body,
      metadata: input.metadata ?? {},
      location: input.location,
      date: input.date,
      severity: input.severity,
      validUntil: input.validUntil,
      status: input.status ?? 'PUBLISHED',
      reportsCount: 0,
      createdAt: now,
      updatedAt: now,
    };

    posts.push(post);
    await this.repository.setAll(input.tenantId, posts);
    return post;
  }

  async update(
    tenantId: string,
    id: string,
    patch: PostPatch,
  ): Promise<PostEntity> {
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }

    const base = this.normalizePost(tenantId, posts[index]);
    const now = new Date().toISOString();
    const status = patch.status ?? base.status ?? 'PUBLISHED';
    const hiddenAt =
      status === 'HIDDEN'
        ? patch.hiddenAt ?? posts[index].hiddenAt ?? now
        : undefined;
    const hiddenReason =
      status === 'HIDDEN'
        ? patch.hiddenReason ?? base.hiddenReason ?? 'hidden_by_staff'
        : undefined;

    const updated: PostEntity = {
      ...base,
      type: patch.type ?? base.type,
      category: patch.category ?? base.category,
      title: patch.title ?? base.title,
      body: patch.body ?? base.body,
      metadata: patch.metadata ?? base.metadata,
      location: patch.location ?? base.location,
      date: patch.date ?? base.date,
      severity: patch.severity ?? base.severity,
      validUntil: patch.validUntil ?? base.validUntil,
      status,
      hiddenAt,
      hiddenReason,
      updatedAt: now,
    };

    posts[index] = updated;
    await this.repository.setAll(tenantId, posts);
    return updated;
  }

  async hide(
    tenantId: string,
    id: string,
    reason: string,
  ): Promise<PostEntity> {
    const normalizedReason = reason?.trim();
    if (!normalizedReason) {
      throw new BadRequestException('reason ist erforderlich');
    }
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }
    const now = new Date().toISOString();
    const updated: PostEntity = {
      ...this.normalizePost(tenantId, posts[index]),
      status: 'HIDDEN',
      hiddenAt: now,
      hiddenReason: normalizedReason,
      updatedAt: now,
    };
    posts[index] = updated;
    await this.repository.setAll(tenantId, posts);
    return updated;
  }

  async report(
    tenantId: string,
    id: string,
    reporterUserId: string,
  ): Promise<{ post: PostEntity; alreadyReported: boolean }> {
    const normalizedReporter = reporterUserId.trim();
    if (!normalizedReporter) {
      throw new BadRequestException('reporterUserId ist erforderlich');
    }
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }
    const now = new Date().toISOString();
    const normalized = this.normalizePost(tenantId, posts[index]);
    const reports = await this.reportRepository.getAll(tenantId);
    const existingReports = reports.filter((entry) => entry.postId === id);
    const uniqueReporters = new Map<string, PostReport>();
    existingReports.forEach((entry) => {
      if (!uniqueReporters.has(entry.reporterUserId)) {
        uniqueReporters.set(entry.reporterUserId, entry);
      }
    });
    const alreadyReported = uniqueReporters.has(normalizedReporter);
    if (!alreadyReported) {
      const newReport: PostReport = {
        id: randomUUID(),
        tenantId,
        postId: id,
        reporterUserId: normalizedReporter,
        createdAt: now,
      };
      reports.push(newReport);
      uniqueReporters.set(normalizedReporter, newReport);
      await this.reportRepository.setAll(tenantId, reports);
    }

    const nextReportsCount = uniqueReporters.size;
    const nextReportedAt =
      nextReportsCount > 0 ? normalized.reportedAt ?? now : undefined;
    const needsUpdate =
      normalized.reportsCount !== nextReportsCount ||
      normalized.reportedAt !== nextReportedAt;
    if (needsUpdate) {
      const updated: PostEntity = {
        ...normalized,
        reportsCount: nextReportsCount,
        reportedAt: nextReportedAt,
        updatedAt: now,
      };
      posts[index] = updated;
      await this.repository.setAll(tenantId, posts);
      return { post: updated, alreadyReported };
    }
    return { post: normalized, alreadyReported };
  }

  async getAll(options: ListOptions): Promise<PostEntity[]> {
    const posts = await this.repository.getAll(options.tenantId);
    const normalized = posts.map((post) =>
      this.normalizePost(options.tenantId, post),
    );
    const statusFilter = this.resolveStatusFilter(options);
    const query = options.query?.trim().toLowerCase();
    const filtered = normalized.filter((post) => {
      if (!this.matchesVisibility(post, options, statusFilter)) {
        return false;
      }
      if (options.reportedOnly) {
        if (!(post.reportedAt || (post.reportsCount ?? 0) > 0)) {
          return false;
        }
      }
      if (options.type && post.type !== options.type) {
        return false;
      }
      if (query) {
        const haystack = `${post.title} ${post.body}`.toLowerCase();
        if (!haystack.includes(query)) {
          return false;
        }
      }
      return true;
    });
    const sorted = filtered.sort(
      (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
    );
    return this.applyPagination(sorted, options);
  }

  async hidePost(
    tenantId: string,
    id: string,
    reason?: string,
  ): Promise<PostEntity> {
    return this.hide(tenantId, id, reason ?? '');
  }

  async unhidePost(tenantId: string, id: string): Promise<PostEntity> {
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }
    const now = new Date().toISOString();
    const normalized = this.normalizePost(tenantId, posts[index]);
    const updated: PostEntity = {
      ...normalized,
      status: 'PUBLISHED',
      hiddenAt: undefined,
      hiddenReason: undefined,
      updatedAt: now,
    };
    posts[index] = updated;
    await this.repository.setAll(tenantId, posts);
    return updated;
  }

  async resetReports(tenantId: string, id: string): Promise<PostEntity> {
    const posts = await this.repository.getAll(tenantId);
    const index = posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }
    const now = new Date().toISOString();
    const normalized = this.normalizePost(tenantId, posts[index]);
    const updated: PostEntity = {
      ...normalized,
      reportsCount: 0,
      reportedAt: undefined,
      updatedAt: now,
    };
    posts[index] = updated;
    await this.repository.setAll(tenantId, posts);
    return updated;
  }

  private normalizePost(tenantId: string, post: PostEntity): PostEntity {
    const authorUserId =
      post.authorUserId ?? (post as { authorId?: string }).authorId;
    return {
      ...post,
      tenantId: post.tenantId ?? tenantId,
      authorUserId,
      metadata: post.metadata ?? {},
      status: post.status ?? 'PUBLISHED',
      reportsCount: post.reportsCount ?? 0,
    };
  }

  private resolveStatusFilter(options: {
    status?: PostStatus;
    includeHidden?: boolean;
  }) {
    if (options.status) {
      return options.status;
    }
    if (options.includeHidden) {
      return undefined;
    }
    return 'PUBLISHED';
  }

  private matchesVisibility(
    post: PostEntity,
    options: { includeHidden?: boolean; viewerUserId?: string },
    statusFilter?: PostStatus,
  ) {
    if (post.status === 'HIDDEN') {
      if (options.includeHidden) {
        return true;
      }
      if (options.viewerUserId && post.authorUserId === options.viewerUserId) {
        return true;
      }
      return false;
    }
    if (statusFilter && post.status !== statusFilter) {
      return false;
    }
    return true;
  }

  private applyPagination(
    items: PostEntity[],
    options: { limit?: number; offset?: number },
  ) {
    const offset = options.offset ?? 0;
    const rawLimit = options.limit ?? PostsService.DEFAULT_LIMIT;
    const limited = Math.min(
      Math.max(rawLimit, 1),
      PostsService.MAX_LIMIT,
    );
    return items.slice(offset, offset + limited);
  }
}
