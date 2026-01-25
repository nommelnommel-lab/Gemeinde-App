import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Header,
  Headers,
  NotFoundException,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { ResidentsService } from './residents.service';
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
  constructor(
    private readonly usersService: UsersService,
    private readonly residentsService: ResidentsService,
  ) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  async listUsers(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Query('q') q?: string,
  ) {
    const tenantId = requireTenant(headers);
    const users = await this.usersService.list(tenantId, q);
    const residents = await this.residentsService.list(tenantId);
    const residentMap = new Map(residents.map((resident) => [resident.id, resident]));
    return {
      users: users.map((user) => ({
        id: user.id,
        email: user.email,
        displayName: this.formatDisplayName(residentMap.get(user.residentId)),
        residentId: user.residentId,
        role: user.role,
        createdAt: user.createdAt,
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
    const userId = payload.userId?.trim();
    const email = payload.email?.trim();
    const hasUserId = Boolean(userId);
    const hasEmail = Boolean(email);
    if (hasUserId === hasEmail) {
      throw new BadRequestException(
        'Genau eine der Angaben userId oder email ist erforderlich',
      );
    }

    const user = hasUserId
      ? await this.usersService.getById(tenantId, userId as string)
      : await this.usersService.findByEmail(tenantId, email as string);
    if (!user) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }
    const updated = await this.usersService.update(tenantId, user.id, { role });
    const residents = await this.residentsService.list(tenantId);
    const residentMap = new Map(residents.map((resident) => [resident.id, resident]));
    return {
      ok: true,
      user: {
        id: updated.id,
        email: updated.email,
        displayName: this.formatDisplayName(residentMap.get(updated.residentId)),
        residentId: updated.residentId,
        role: updated.role,
        createdAt: updated.createdAt,
      },
    };
  }

  private formatDisplayName(
    resident?: { firstName?: string; lastName?: string } | null,
  ) {
    if (!resident) {
      return null;
    }
    const firstName = resident.firstName?.trim() ?? '';
    const lastName = resident.lastName?.trim() ?? '';
    if (!firstName && !lastName) {
      return null;
    }
    if (!lastName) {
      return firstName;
    }
    const initial = lastName.charAt(0);
    return `${firstName} ${initial}.`;
  }
}
