import {
  Body,
  Controller,
  Headers,
  Post,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { requireTenant } from '../tenant/tenant-auth';
import { TouristRedeemDto } from './dto/tourist-redeem.dto';
import { TouristAccessCodesService } from './tourist-access-codes.service';
import { UserRole } from './user-roles';
import { JwtAccessPayload } from './auth.types';
import { getJwtSecret } from './jwt.utils';

@Controller('api/tourist')
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class TouristRedeemController {
  constructor(private readonly touristCodes: TouristAccessCodesService) {}

  @Post('redeem')
  async redeem(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: TouristRedeemDto,
  ) {
    const tenantId = requireTenant(headers);
    const redeemed = await this.touristCodes.redeem({
      tenantId,
      code: payload.code,
      deviceId: payload.deviceId,
    });
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + redeemed.durationDays);

    const tokenPayload: JwtAccessPayload = {
      sub: payload.deviceId,
      tenantId,
      residentId: '',
      email: '',
      role: UserRole.TOURIST,
      expiresAt: expiresAt.toISOString(),
    };

    const accessToken = jwt.sign(tokenPayload, getJwtSecret(), {
      expiresIn: redeemed.durationDays * 24 * 60 * 60,
    });

    return {
      accessToken,
      refreshToken: '',
      expiresAt: tokenPayload.expiresAt,
      user: {
        id: payload.deviceId,
        tenantId,
        residentId: '',
        displayName: 'Tourist',
        email: '',
        role: UserRole.TOURIST,
      },
    };
  }
}
