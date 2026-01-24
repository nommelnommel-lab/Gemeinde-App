import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AdminActivationCodesController } from './admin-activation-codes.controller';
import { AdminResidentsController } from './admin-residents.controller';
import { AdminUsersController } from './admin-users.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthSharedModule } from './auth-shared.module';
import { ResidentsService } from './residents.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [
    AuthController,
    AdminActivationCodesController,
    AdminResidentsController,
    AdminUsersController,
  ],
  providers: [AuthService, AdminGuard, ResidentsService],
})
export class AuthModule {}
