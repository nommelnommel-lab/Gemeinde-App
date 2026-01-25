import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import { dirname, join } from 'path';
import { ContentType } from '../content/content.types';
import { PostEntity, PostType } from './posts.types';

type PostInput = {
  type: PostType;
  title: string;
  body: string;
  authorId?: string;
  category?: PostEntity['category'];
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
};

type ListOptions = {
  type?: PostType;
  limit?: number;
};

@Injectable()
export class PostsService implements OnModuleInit {
  private posts: PostEntity[] = [];
  private readonly dataFilePath = join(process.cwd(), 'data', 'posts.json');

  async onModuleInit() {
    await this.ensureDataFile();
    await this.loadPosts();
  }

  async getAll(options: ListOptions = {}): Promise<PostEntity[]> {
    const { type, limit } = options;
    const filtered = type
      ? this.posts.filter((post) => post.type === type)
      : [...this.posts];
    const sorted = filtered.sort(
      (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
    );
    if (typeof limit === 'number') {
      return sorted.slice(0, limit);
    }
    return sorted;
  }

  async getById(id: string): Promise<PostEntity> {
    const post = this.posts.find((item) => item.id === id);
    if (!post) {
      throw new NotFoundException('Post nicht gefunden');
    }
    return post;
  }

  async create(input: PostInput): Promise<PostEntity> {
    const now = new Date().toISOString();
    const post: PostEntity = {
      id: randomUUID(),
      type: input.type,
      category: input.category,
      authorId: input.authorId,
      title: input.title,
      body: input.body,
      location: input.location,
      date: input.date,
      severity: input.severity,
      validUntil: input.validUntil,
      createdAt: now,
      updatedAt: now,
    };

    this.posts.push(post);
    await this.persist();
    return post;
  }

  async update(id: string, input: PostInput): Promise<PostEntity> {
    const index = this.posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }

    const updated: PostEntity = {
      ...this.posts[index],
      type: input.type,
      category: input.category ?? this.posts[index].category,
      title: input.title,
      body: input.body,
      location: input.location,
      date: input.date,
      severity: input.severity,
      validUntil: input.validUntil,
      updatedAt: new Date().toISOString(),
    };

    this.posts[index] = updated;
    await this.persist();
    return updated;
  }

  async remove(id: string): Promise<void> {
    const index = this.posts.findIndex((item) => item.id === id);
    if (index === -1) {
      throw new NotFoundException('Post nicht gefunden');
    }

    this.posts.splice(index, 1);
    await this.persist();
  }

  private async ensureDataFile() {
    const dataDir = dirname(this.dataFilePath);
    await fs.mkdir(dataDir, { recursive: true });
    try {
      await fs.access(this.dataFilePath);
    } catch {
      const seed = this.createSeedPosts();
      await this.writeFileAtomic(seed);
    }
  }

  private async loadPosts() {
    const file = await fs.readFile(this.dataFilePath, 'utf8');
    const parsed = JSON.parse(file);
    this.posts = Array.isArray(parsed) ? (parsed as PostEntity[]) : [];
  }

  private async persist() {
    await this.writeFileAtomic(this.posts);
  }

  private async writeFileAtomic(data: PostEntity[]) {
    const tempPath = `${this.dataFilePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, this.dataFilePath);
  }

  private createSeedPosts(): PostEntity[] {
    const now = new Date().toISOString();
    return [
      {
        id: randomUUID(),
        type: ContentType.OFFICIAL_EVENT,
        authorId: 'system',
        title: 'Ernte-Dank Gottesdienst',
        body: 'Wir feiern gemeinsam mit Musik und anschließendem Imbiss.',
        location: 'Kirche St. Markus',
        date: '2024-10-06T09:00:00.000Z',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        type: ContentType.OFFICIAL_NEWS,
        authorId: 'system',
        title: 'Neue Öffnungszeiten im Pfarrbüro',
        body: 'Das Pfarrbüro ist ab Oktober dienstags und donnerstags geöffnet.',
        validUntil: '2024-12-01T00:00:00.000Z',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        type: ContentType.OFFICIAL_WARNING,
        authorId: 'system',
        title: 'Sturmböen am Wochenende',
        body: 'Bitte achtet auf lose Gegenstände im Außenbereich.',
        severity: 'medium',
        validUntil: '2024-09-23T18:00:00.000Z',
        createdAt: now,
        updatedAt: now,
      },
    ];
  }
}
