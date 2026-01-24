import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Role } from '../auth/roles';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PostsService } from './posts.service';
import { PostEntity, PostType } from './posts.types';

type PostPayload = {
  type?: PostType;
  title?: string;
  body?: string;
  location?: string;
  date?: string;
  severity?: 'low' | 'medium' | 'high';
  validUntil?: string;
};

@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  async getPosts(
    @Query('type') type?: string,
    @Query('limit') limit?: string,
  ): Promise<PostEntity[]> {
    const parsedType = type ? this.parseType(type) : undefined;
    const parsedLimit = limit ? this.parseLimit(limit) : undefined;
    return this.postsService.getAll({ type: parsedType, limit: parsedLimit });
  }

  @Get(':id')
  async getPost(@Param('id') id: string): Promise<PostEntity> {
    return this.postsService.getById(id);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles(Role.STAFF)
  async createPost(
    @Body() payload: PostPayload,
  ): Promise<PostEntity> {
    const data = this.validatePayload(payload);
    return this.postsService.create(data);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(Role.STAFF)
  async updatePost(
    @Param('id') id: string,
    @Body() payload: PostPayload,
  ): Promise<PostEntity> {
    const data = this.validatePayload(payload);
    return this.postsService.update(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(Role.STAFF)
  async deletePost(
    @Param('id') id: string,
  ) {
    await this.postsService.remove(id);
    return { ok: true };
  }

  private validatePayload(payload: PostPayload) {
    const type = this.requireType(payload.type);
    const title = this.requireString(payload.title, 'title');
    const body = this.requireString(payload.body, 'body');
    const location = payload.location?.trim() || undefined;
    const date = payload.date?.trim();
    const validUntil = payload.validUntil?.trim();

    if (type === 'event') {
      if (!date) {
        throw new BadRequestException('date ist erforderlich');
      }
    }

    if (date && Number.isNaN(Date.parse(date))) {
      throw new BadRequestException('date muss ein gültiger ISO-8601-String sein');
    }

    if (validUntil && Number.isNaN(Date.parse(validUntil))) {
      throw new BadRequestException(
        'validUntil muss ein gültiger ISO-8601-String sein',
      );
    }

    const severity = payload.severity;
    if (type === 'warning') {
      if (!severity) {
        throw new BadRequestException('severity ist erforderlich');
      }
      this.requireSeverity(severity);
    } else if (severity) {
      this.requireSeverity(severity);
    }

    return {
      type,
      title,
      body,
      location,
      date,
      severity,
      validUntil,
    };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }

  private requireType(value: PostType | undefined): PostType {
    if (!value) {
      throw new BadRequestException('type ist erforderlich');
    }
    return this.parseType(value);
  }

  private parseType(value: string): PostType {
    const normalized = value.trim() as PostType;
    const allowed: PostType[] = [
      'event',
      'news',
      'warning',
      'market',
      'help',
      'cafe',
      'kids',
    ];
    if (!allowed.includes(normalized)) {
      throw new BadRequestException('type ist ungültig');
    }
    return normalized;
  }

  private parseLimit(value: string): number {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException('limit muss eine positive Zahl sein');
    }
    return parsed;
  }

  private requireSeverity(value: string) {
    if (!['low', 'medium', 'high'].includes(value)) {
      throw new BadRequestException('severity ist ungültig');
    }
  }

}
