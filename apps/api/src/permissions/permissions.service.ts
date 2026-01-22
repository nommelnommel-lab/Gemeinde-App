import { Injectable } from '@nestjs/common';

@Injectable()
export class PermissionsService {
  isAdmin(adminKeyHeader: string | undefined): boolean {
    const adminKey = process.env.ADMIN_KEY;

    if (!adminKey) {
      return false;
    }

    return adminKeyHeader === adminKey;
  }
}
