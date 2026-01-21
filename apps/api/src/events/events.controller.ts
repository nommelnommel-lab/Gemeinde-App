import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { EventsService } from './events.service';
import { EventEntity } from './events.types';

type EventPayload = {
  title?: string;
  description?: string;
  date?: string;
  location?: string;
};

@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Get()
  async getEvents(): Promise<EventEntity[]> {
    return this.eventsService.getAll();
  }

  @Get(':id')
  async getEvent(@Param('id') id: string): Promise<EventEntity> {
    return this.eventsService.getById(id);
  }

  @Post()
  async createEvent(@Body() payload: EventPayload): Promise<EventEntity> {
    const data = this.validatePayload(payload);
    return this.eventsService.create(data);
  }

  @Put(':id')
  async updateEvent(
    @Param('id') id: string,
    @Body() payload: EventPayload,
  ): Promise<EventEntity> {
    const data = this.validatePayload(payload);
    return this.eventsService.update(id, data);
  }

  @Delete(':id')
  async deleteEvent(@Param('id') id: string) {
    await this.eventsService.remove(id);
    return { ok: true };
  }

  private validatePayload(payload: EventPayload) {
    const title = this.requireString(payload.title, 'title');
    const description = this.requireString(payload.description, 'description');
    const location = this.requireString(payload.location, 'location');
    const date = this.requireString(payload.date, 'date');
    if (Number.isNaN(Date.parse(date))) {
      throw new BadRequestException('date muss ein gültiger ISO-8601-String sein');
    }

    return { title, description, location, date };
  }

  private requireString(value: string | undefined, field: string) {
    if (!value || value.trim().length === 0) {
      throw new BadRequestException(`${field} ist erforderlich`);
    }
    return value.trim();
  }
}
