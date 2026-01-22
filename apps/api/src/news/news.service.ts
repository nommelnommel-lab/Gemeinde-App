import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';
import { NewsInputDto } from './news.dto';
import { NewsEntity } from './news.types';

@Injectable()
export class NewsService implements OnModuleInit {
  private news: NewsEntity[] = [];
  private readonly dataFilePath = join(process.cwd(), 'data', 'news.json');

  async onModuleInit() {
    await this.ensureDataFile();
    await this.loadNews();
  }

  async getAll(): Promise<NewsEntity[]> {
    return [...this.news].sort(
      (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
    );
  }

  async getById(id: string): Promise<NewsEntity> {
    const item = this.news.find((newsItem) => newsItem.id === id);
    if (!item) {
      throw new NotFoundException('News nicht gefunden');
    }
    return item;
  }

  async create(input: NewsInputDto): Promise<NewsEntity> {
    const now = new Date().toISOString();
    const item: NewsEntity = {
      id: randomUUID(),
      title: input.title,
      body: input.body,
      category: input.category,
      createdAt: now,
      updatedAt: now,
    };

    this.news.push(item);
    await this.persist();
    return item;
  }

  async update(id: string, input: NewsInputDto): Promise<NewsEntity> {
    const index = this.news.findIndex((newsItem) => newsItem.id === id);
    if (index === -1) {
      throw new NotFoundException('News nicht gefunden');
    }

    const updated: NewsEntity = {
      ...this.news[index],
      title: input.title,
      body: input.body,
      category: input.category,
      updatedAt: new Date().toISOString(),
    };

    this.news[index] = updated;
    await this.persist();
    return updated;
  }

  async remove(id: string): Promise<void> {
    const index = this.news.findIndex((newsItem) => newsItem.id === id);
    if (index === -1) {
      throw new NotFoundException('News nicht gefunden');
    }

    this.news.splice(index, 1);
    await this.persist();
  }

  private async ensureDataFile() {
    const dataDir = dirname(this.dataFilePath);
    await fs.mkdir(dataDir, { recursive: true });
    try {
      await fs.access(this.dataFilePath);
    } catch {
      const seed = this.createSeedNews();
      await this.writeFileAtomic(seed);
    }
  }

  private async loadNews() {
    const file = await fs.readFile(this.dataFilePath, 'utf8');
    const parsed = JSON.parse(file);
    this.news = Array.isArray(parsed) ? (parsed as NewsEntity[]) : [];
  }

  private async persist() {
    await this.writeFileAtomic(this.news);
  }

  private async writeFileAtomic(data: NewsEntity[]) {
    const tempPath = `${this.dataFilePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, this.dataFilePath);
  }

  private createSeedNews(): NewsEntity[] {
    const now = new Date().toISOString();
    return [
      {
        id: randomUUID(),
        title: 'Neuer Gemeindebrief online',
        body: 'Der aktuelle Gemeindebrief steht ab sofort als PDF zum Download bereit.',
        category: 'Aktuelles',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Spendenaktion abgeschlossen',
        body: 'Dank eurer Hilfe konnten wir das Spendenziel für die Dachsanierung erreichen.',
        category: 'Gemeinde',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Neues Kursangebot startet',
        body: 'Ab Oktober bieten wir einen wöchentlichen Kurs zum Thema Achtsamkeit an.',
        category: 'Angebote',
        createdAt: now,
        updatedAt: now,
      },
      {
        id: randomUUID(),
        title: 'Freiwillige gesucht',
        body: 'Für das Herbstfest werden helfende Hände für Auf- und Abbau benötigt.',
        category: 'Mitmachen',
        createdAt: now,
        updatedAt: now,
      },
    ];
  }
}
