import { Module } from '@nestjs/common';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [PostsController],
  providers: [PostsService],
})
export class PostsModule {}
