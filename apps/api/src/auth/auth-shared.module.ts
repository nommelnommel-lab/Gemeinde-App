import { Module } from '@nestjs/common';
import { AccessTokenService } from './access-token.service';
import { RolesGuard } from './roles.guard';
import { UsersService } from './users.service';

@Module({
  providers: [AccessTokenService, RolesGuard, UsersService],
  exports: [AccessTokenService, RolesGuard, UsersService],
})
export class AuthSharedModule {}
