import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AdminActivationCodesController } from './admin-activation-codes.controller';
import { AdminResidentsController } from './admin-residents.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { ResidentsService } from './residents.service';

@Module({
  controllers: [AuthController, AdminActivationCodesController, AdminResidentsController],
  providers: [AuthService, AdminGuard, ResidentsService],
})
export class AuthModule {}
