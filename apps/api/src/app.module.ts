import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { HealthModule } from './health/health.module';
import { NewsModule } from './news/news.module';
import { PermissionsModule } from './permissions/permissions.module';
import { PostsModule } from './posts/posts.module';
import { TenantModule } from './tenant/tenant.module';
import { WarningsModule } from './warnings/warnings.module';
import { MunicipalityModule } from './municipality/municipality.module';
import { AuthModule } from './auth/auth.module';
import { TourismModule } from './tourism/tourism.module';
import { AdminModule } from './admin/admin.module';

@Module({
  controllers: [AppController],
  imports: [
    AuthModule,
    EventsModule,
    HealthModule,
    NewsModule,
    PermissionsModule,
    PostsModule,
    TenantModule,
    WarningsModule,
    AuthModule,
    MunicipalityModule,
    TourismModule,
    AdminModule,
  ],
})
export class AppModule {}
