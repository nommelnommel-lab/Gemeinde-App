import { Injectable } from '@nestjs/common';
import { ContentType } from '../content/content.types';
import { verifyAccessToken } from '../auth/jwt.utils';
import { UserRole } from '../auth/user-roles';

type PermissionsPayload = {
  role: UserRole;
  isAdmin: boolean;
  canCreate: {
    marketplace: boolean;
    help: boolean;
    movingClearance: boolean;
    cafeMeetup: boolean;
    kidsMeetup: boolean;
    apartmentSearch: boolean;
    lostFound: boolean;
    rideSharing: boolean;
    jobsLocal: boolean;
    volunteering: boolean;
    giveaway: boolean;
    skillExchange: boolean;
    officialNews: boolean;
    officialWarnings: boolean;
    officialEvents: boolean;
  };
  canModerateUserContent: boolean;
  canManageResidents: boolean;
  canGenerateActivationCodes: boolean;
  canManageRoles: boolean;
};

const userCreatePermissions = {
  marketplace: true,
  help: true,
  movingClearance: true,
  cafeMeetup: true,
  kidsMeetup: true,
  apartmentSearch: true,
  lostFound: true,
  rideSharing: true,
  jobsLocal: true,
  volunteering: true,
  giveaway: true,
  skillExchange: true,
};

@Injectable()
export class PermissionsService {
  getPermissions(
    headers: Record<string, string | string[] | undefined>,
  ): PermissionsPayload {
    const payload = verifyAccessToken(headers);
    const role = payload?.role ?? UserRole.USER;

    const canCreateOfficial = role === UserRole.STAFF || role === UserRole.ADMIN;
    const canModerateUserContent = role !== UserRole.USER;
    const isAdmin = role === UserRole.ADMIN;

    return {
      role,
      isAdmin,
      canCreate: {
        ...userCreatePermissions,
        officialNews: canCreateOfficial,
        officialWarnings: canCreateOfficial,
        officialEvents: canCreateOfficial,
      },
      canModerateUserContent,
      canManageResidents: isAdmin,
      canGenerateActivationCodes: isAdmin,
      canManageRoles: isAdmin,
    };
  }

  canCreateOfficialContent(role: UserRole) {
    return role === UserRole.STAFF || role === UserRole.ADMIN;
  }

  isUserContent(type: ContentType) {
    return (
      type !== ContentType.OFFICIAL_EVENT &&
      type !== ContentType.OFFICIAL_NEWS &&
      type !== ContentType.OFFICIAL_WARNING
    );
  }
}
