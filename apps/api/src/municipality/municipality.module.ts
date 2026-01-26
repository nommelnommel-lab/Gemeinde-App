import { Module } from '@nestjs/common';
import { AdminGuard } from '../admin/admin.guard';
import { AuthSharedModule } from '../auth/auth-shared.module';
import { MunicipalityClubsController } from './clubs/municipality-clubs.controller';
import { MunicipalityClubsService } from './clubs/municipality-clubs.service';
import { MunicipalityEventsController } from './events/municipality-events.controller';
import { MunicipalityEventsService } from './events/municipality-events.service';
import { MunicipalityFeedController } from './feed/municipality-feed.controller';
import { MunicipalityFormsController } from './forms/municipality-forms.controller';
import { MunicipalityFormsService } from './forms/municipality-forms.service';
import { MunicipalityImportController } from './import/municipality-import.controller';
import { MunicipalityPostsController } from './posts/municipality-posts.controller';
import { MunicipalityPostsService } from './posts/municipality-posts.service';
import { MunicipalityPlacesController } from './places/municipality-places.controller';
import { MunicipalityPlacesService } from './places/municipality-places.service';
import { MunicipalityProfileController } from './profile/municipality-profile.controller';
import { MunicipalityProfileService } from './profile/municipality-profile.service';
import { MunicipalityServicesController } from './services/municipality-services.controller';
import { MunicipalityServicesService } from './services/municipality-services.service';
import { TenantSettingsController } from './tenant-settings/tenant-settings.controller';
import { TenantSettingsService } from './tenant-settings/tenant-settings.service';
import { MunicipalityVerwaltungController } from './verwaltung/municipality-verwaltung.controller';
import { MunicipalityVerwaltungService } from './verwaltung/municipality-verwaltung.service';
import { MunicipalityWastePickupsController } from './waste-pickups/municipality-waste-pickups.controller';
import { MunicipalityWastePickupsService } from './waste-pickups/municipality-waste-pickups.service';

@Module({
  imports: [AuthSharedModule],
  controllers: [
    TenantSettingsController,
    MunicipalityProfileController,
    MunicipalityFormsController,
    MunicipalityEventsController,
    MunicipalityPostsController,
    MunicipalityPlacesController,
    MunicipalityServicesController,
    MunicipalityVerwaltungController,
    MunicipalityClubsController,
    MunicipalityWastePickupsController,
    MunicipalityFeedController,
    MunicipalityImportController,
  ],
  providers: [
    TenantSettingsService,
    MunicipalityProfileService,
    MunicipalityFormsService,
    MunicipalityEventsService,
    MunicipalityPostsService,
    MunicipalityPlacesService,
    MunicipalityServicesService,
    MunicipalityVerwaltungService,
    MunicipalityClubsService,
    MunicipalityWastePickupsService,
    AdminGuard,
  ],
  exports: [MunicipalityPostsService],
})
export class MunicipalityModule {}
