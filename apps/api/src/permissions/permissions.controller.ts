import { Controller, Get, Headers } from '@nestjs/common';
import { PermissionsService } from './permissions.service';

@Controller('permissions')
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Get()
  getPermissions(@Headers('x-admin-key') adminKeyHeader?: string) {
    return {
      isAdmin: this.permissionsService.isAdmin(adminKeyHeader),
    };
  }
}
