import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { NewsModule } from './news/news.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, NewsModule],
})
export class AppModule {}
