import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { NewsModule } from './news/news.module';
import { WarningsModule } from './warnings/warnings.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, NewsModule, WarningsModule],
})
export class AppModule {}
