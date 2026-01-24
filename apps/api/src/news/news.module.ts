import { Module } from '@nestjs/common';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { NewsController } from './news.controller';
import { NewsService } from './news.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [NewsController],
  providers: [NewsService],
})
export class NewsModule {}
