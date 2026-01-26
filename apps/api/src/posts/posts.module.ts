import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { PermissionsModule } from '../permissions/permissions.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';

@Module({
  imports: [AuthSharedModule, PermissionsModule],
  controllers: [PostsController],
  providers: [PostsService],
})
export class PostsModule {}
