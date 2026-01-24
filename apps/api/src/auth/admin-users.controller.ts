import {
  BadRequestException,
  Body,
  Controller,
  Headers,
  NotFoundException,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsEmail, IsIn, IsOptional, IsUUID } from 'class-validator';
import { AdminGuard } from '../admin/admin.guard';
import { requireTenant } from '../tenant/tenant-auth';
import { Role, normalizeRole } from './roles';
import { UsersService } from './users.service';

class AdminUserRoleDto {
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsIn(Object.values(Role))
  role!: Role;
}

@Controller('api/admin/users')
@UseGuards(AdminGuard)
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class AdminUsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('role')
  async updateRole(
    @Headers() headers: Record<string, string | string[] | undefined>,
    @Body() payload: AdminUserRoleDto,
  ) {
    const tenantId = requireTenant(headers);
    if (!payload.userId && !payload.email) {
      throw new BadRequestException('userId oder email ist erforderlich');
    }

    const role = normalizeRole(payload.role);
    const user = payload.userId
      ? await this.usersService.getById(tenantId, payload.userId)
      : await this.usersService.findByEmail(tenantId, payload.email ?? '');

    if (!user) {
      throw new NotFoundException('Benutzer nicht gefunden');
    }

    const updated = await this.usersService.update(tenantId, user.id, { role });
    return { userId: updated.id, role: updated.role };
  }
}
