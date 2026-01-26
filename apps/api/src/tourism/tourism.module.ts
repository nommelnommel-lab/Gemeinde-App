import { Module } from '@nestjs/common';
import { AdminTourismController } from './admin-tourism.controller';
import { TourismController } from './tourism.controller';
import { TourismService } from './tourism.service';

@Module({
  controllers: [TourismController, AdminTourismController],
  providers: [TourismService],
})
export class TourismModule {}
