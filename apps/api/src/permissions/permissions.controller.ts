import { Controller, Get, Headers } from '@nestjs/common';
import { PermissionsService } from './permissions.service';

@Controller('permissions')
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Get()
  getPermissions(
    @Headers() headers: Record<string, string | string[] | undefined>,
  ) {
    return this.permissionsService.getPermissions(headers);
  }
}
