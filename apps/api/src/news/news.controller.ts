import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/user-roles';
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
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async createNews(
    @Body() payload: NewsPayloadDto,
  ): Promise<NewsEntity> {
    const data = this.validatePayload(payload);
    return this.newsService.create(data);
  }

  @Put(':id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async updateNews(
    @Param('id') id: string,
    @Body() payload: NewsPayloadDto,
  ): Promise<NewsEntity> {
    const data = this.validatePayload(payload);
    return this.newsService.update(id, data);
  }

  @Delete(':id')
  @UseGuards(new JwtAuthGuard(), new RolesGuard())
  @Roles(UserRole.STAFF, UserRole.ADMIN)
  async deleteNews(
    @Param('id') id: string,
  ) {
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

}
