import { Module } from '@nestjs/common';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { WarningsController } from './warnings.controller';
import { WarningsService } from './warnings.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [WarningsController],
  providers: [WarningsService],
})
export class WarningsModule {}
