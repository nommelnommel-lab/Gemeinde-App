import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';
import { PermissionsModule } from './permissions/permissions.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule, PermissionsModule],
})
export class AppModule {}
