import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Headers,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { NewsPayloadDto } from './news.dto';
import { NewsService } from './news.service';
import { NewsEntity } from './news.types';

@Controller('news')
export class NewsController {
  constructor(private readonly newsService: NewsService) {}

  @Get()
  async getNews(): Promise<NewsEntity[]> {
    return this.newsService.getAll();
  }

  @Get(':id')
  async getNewsById(@Param('id') id: string): Promise<NewsEntity> {
    return this.newsService.getById(id);
  }

  @Post()
  async createNews(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: NewsPayloadDto,
  ): Promise<NewsEntity> {
    this.requireAdmin(headers);
    const data = this.validatePayload(payload);
    return this.newsService.create(data);
  }

  @Put(':id')
  async updateNews(
    @Param('id') id: string,
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: NewsPayloadDto,
  ): Promise<NewsEntity> {
    this.requireAdmin(headers);
    const data = this.validatePayload(payload);
    return this.newsService.update(id, data);
  }

  @Delete(':id')
  async deleteNews(
    @Param('id') id: string,
    @Headers() headers: Record<string, string | string[] | undefined>,
  ) {
    this.requireAdmin(headers);
    await this.newsService.remove(id);
    return { ok: true };
  }

  private validatePayload(payload: NewsPayloadDto) {
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const category = this.optionalString(payload.category);

    return { title, body, category };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private optionalString(value: string | undefined) {
    if (value === undefined) {
      return undefined;
    }
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      throw new BadRequestException('category darf nicht leer sein');
    }
    return trimmed;
  }

  private requireAdmin(
    headers: Record<string, string | string[] | undefined>,
  ) {
    const adminKey = process.env.ADMIN_KEY;
    if (!adminKey) {
      return;
    }

    const providedHeader = headers['x-admin-key'];
    const provided = Array.isArray(providedHeader)
      ? providedHeader[0]
      : providedHeader;

    if (provided !== adminKey) {
      throw new ForbiddenException('Ungültiger Admin-Schlüssel');
    }
  }
}
