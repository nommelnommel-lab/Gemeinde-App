import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AdminActivationCodesController } from './admin-activation-codes.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  controllers: [AuthController, AdminActivationCodesController],
  providers: [AuthService, AdminGuard],
})
export class AuthModule {}
