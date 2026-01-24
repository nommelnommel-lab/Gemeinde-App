import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { UsersService } from './users.service';
import { isUserRole, normalizeUserRole } from './user-roles';

type RolePayload = {
  userId?: string;
  email?: string;
  role?: string;
};

@Controller('api/admin/users')
@UseGuards(AdminGuard)
export class AdminUsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  async listUsers(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') q?: string,
  ) {
    const tenantId = requireTenant(headers);
    const users = await this.usersService.list(tenantId, q);
    return {
      users: users.map((user) => ({
        id: user.id,
        tenantId: user.tenantId,
        residentId: user.residentId,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      })),
    };
  }

  @Post('role')
  @Header('Cache-Control', 'no-store')
  async setRole(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: RolePayload,
  ) {
    const tenantId = requireTenant(headers);
    if (!payload?.role) {
      throw new BadRequestException('role ist erforderlich');
    }
    if (!isUserRole(payload.role)) {
      throw new BadRequestException('role ist ungültig');
    }
    const role = normalizeUserRole(payload.role);
    let userId = payload.userId?.trim();
    if (!userId && payload.email) {
      const user = await this.usersService.findByEmail(tenantId, payload.email);
      if (!user) {
        throw new BadRequestException('Benutzer nicht gefunden');
      }
      userId = user.id;
    }
    if (!userId) {
      throw new BadRequestException('userId oder email ist erforderlich');
    }
    const updated = await this.usersService.update(tenantId, userId, { role });
    return {
      id: updated.id,
      role: updated.role,
    };
  }
}
