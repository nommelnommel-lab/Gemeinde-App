import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { NewsModule } from './news/news.module';
import { PermissionsModule } from './permissions/permissions.module';
import { WarningsModule } from './warnings/warnings.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, NewsModule, PermissionsModule, WarningsModule],
})
export class AppModule {}
