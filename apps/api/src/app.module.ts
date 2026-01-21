import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { EventsModule } from './events/events.module';

@Module({
  controllers: [AppController],
  imports: [EventsModule],
})
export class AppModule {}
