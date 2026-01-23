import { Module } from '@nestjs/common';
import { MunicipalityClubsController } from './clubs/municipality-clubs.controller';
import { MunicipalityClubsService } from './clubs/municipality-clubs.service';
import { MunicipalityEventsController } from './events/municipality-events.controller';
import { MunicipalityEventsService } from './events/municipality-events.service';
import { MunicipalityFeedController } from './feed/municipality-feed.controller';
import { MunicipalityImportController } from './import/municipality-import.controller';
import { MunicipalityPostsController } from './posts/municipality-posts.controller';
import { MunicipalityPostsService } from './posts/municipality-posts.service';
import { MunicipalityPlacesController } from './places/municipality-places.controller';
import { MunicipalityPlacesService } from './places/municipality-places.service';
import { MunicipalityServicesController } from './services/municipality-services.controller';
import { MunicipalityServicesService } from './services/municipality-services.service';
import { TenantSettingsController } from './tenant-settings/tenant-settings.controller';
import { TenantSettingsService } from './tenant-settings/tenant-settings.service';
import { MunicipalityWastePickupsController } from './waste-pickups/municipality-waste-pickups.controller';
import { MunicipalityWastePickupsService } from './waste-pickups/municipality-waste-pickups.service';
import { AdminGuard } from '../admin/admin.guard';

@Module({
  controllers: [
    TenantSettingsController,
    MunicipalityEventsController,
    MunicipalityPostsController,
    MunicipalityPlacesController,
    MunicipalityServicesController,
    MunicipalityClubsController,
    MunicipalityWastePickupsController,
    MunicipalityFeedController,
    MunicipalityImportController,
  ],
  providers: [
    TenantSettingsService,
    MunicipalityEventsService,
    MunicipalityPostsService,
    MunicipalityPlacesService,
    MunicipalityServicesService,
    MunicipalityClubsService,
    MunicipalityWastePickupsService,
    AdminGuard,
  ],
})
export class MunicipalityModule {}
