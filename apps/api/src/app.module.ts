import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
codex/implement-warnings-crud-in-nestjs-api
import { WarningsModule } from './warnings/warnings.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, WarningsModule],

import { NewsModule } from './news/news.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, NewsModule],
 main
})
export class AppModule {}
