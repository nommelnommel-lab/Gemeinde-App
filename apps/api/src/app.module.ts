import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { HealthModule } from './health/health.module';
import { NewsModule } from './news/news.module';
import { PermissionsModule } from './permissions/permissions.module';
import { PostsModule } from './posts/posts.module';
import { WarningsModule } from './warnings/warnings.module';

@Module({
  controllers: [AppController],
  imports: [
    EventsModule,
    HealthModule,
    NewsModule,
    PermissionsModule,
    PostsModule,
    WarningsModule,
  ],
})
export class AppModule {}
