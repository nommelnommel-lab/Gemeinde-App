import { Body, Controller, Headers, Post, UseGuards } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { AuthService } from './auth.service';

type ActivationCodeRequest = {
  count?: number;
  expiresInDays?: number;
};

@Controller('api/admin/activation-codes')
@UseGuards(AdminGuard)
export class AdminActivationCodesController {
  constructor(private readonly authService: AuthService) {}

  @Post()
  async createActivationCodes(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: ActivationCodeRequest,
  ) {
    const tenantId = requireTenant(headers);
    const count = Number.isInteger(payload?.count) ? payload.count ?? 1 : 1;
    const expiresInDays = Number.isInteger(payload?.expiresInDays)
      ? payload.expiresInDays ?? 30
      : 30;

    const codes = await this.authService.createActivationCodes({
      tenantId,
      count,
      expiresInDays,
      createdBy: 'admin',
    });

    return { tenant: tenantId, codes };
  }
}
