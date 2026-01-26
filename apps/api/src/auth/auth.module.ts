import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AdminActivationCodesController } from './admin-activation-codes.controller';
import { AdminTouristCodesController } from './admin-tourist-codes.controller';
import { AdminResidentsController } from './admin-residents.controller';
import { AdminUsersController } from './admin-users.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthSharedModule } from './auth-shared.module';
import { ResidentsService } from './residents.service';
import { TouristAccessCodesService } from './tourist-access-codes.service';
import { TouristRedeemController } from './tourist-redeem.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [
    AuthController,
    AdminActivationCodesController,
    AdminResidentsController,
    AdminUsersController,
    AdminTouristCodesController,
    TouristRedeemController,
  ],
  providers: [
    AuthService,
    AdminGuard,
    ResidentsService,
    UsersService,
    TouristAccessCodesService,
  ],
})
export class AuthModule {}
