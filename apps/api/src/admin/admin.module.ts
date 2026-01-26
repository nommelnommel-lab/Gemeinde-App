import { Module } from '@nestjs/common';
import { MunicipalityModule } from '../municipality/municipality.module';
import { TourismModule } from '../tourism/tourism.module';
import { AdminDemoController } from './admin-demo.controller';
import { AdminGuard } from './admin.guard';

@Module({
  imports: [MunicipalityModule, TourismModule],
  controllers: [AdminDemoController],
  providers: [AdminGuard],
})
export class AdminModule {}
