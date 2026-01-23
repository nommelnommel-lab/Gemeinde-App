import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthAdminController } from './auth-admin.controller';
import { AuthService } from './auth.service';
import { ActivationCodesService } from './activation-codes.service';
import { ResidentsService } from './residents.service';
import { UsersService } from './users.service';
import { RefreshTokensService } from './refresh-tokens.service';
import { AdminGuard } from '../admin/admin.guard';

@Module({
  controllers: [AuthController, AuthAdminController],
  providers: [
    AuthService,
    ActivationCodesService,
    ResidentsService,
    UsersService,
    RefreshTokensService,
    AdminGuard,
  ],
  exports: [ResidentsService, ActivationCodesService, UsersService],
})
export class AuthModule {}
