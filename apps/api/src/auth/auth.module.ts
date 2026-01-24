import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AdminActivationCodesController } from './admin-activation-codes.controller';
import { AdminResidentsController } from './admin-residents.controller';
import { AdminUsersController } from './admin-users.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { ResidentsService } from './residents.service';
import { UsersService } from './users.service';

@Module({
  controllers: [
    AuthController,
    AdminActivationCodesController,
    AdminResidentsController,
    AdminUsersController,
  ],
  providers: [AuthService, AdminGuard, ResidentsService, UsersService],
})
export class AuthModule {}
