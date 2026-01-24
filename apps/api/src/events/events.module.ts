import { Module } from '@nestjs/common';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [EventsController],
  providers: [EventsService],
})
export class EventsModule {}
