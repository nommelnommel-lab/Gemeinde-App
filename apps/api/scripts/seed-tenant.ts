import { MunicipalityClubsService } from '../src/municipality/clubs/municipality-clubs.service';
import { MunicipalityEventsService } from '../src/municipality/events/municipality-events.service';
import { MunicipalityPlacesService } from '../src/municipality/places/municipality-places.service';
import { MunicipalityPostsService } from '../src/municipality/posts/municipality-posts.service';
import { MunicipalityServicesService } from '../src/municipality/services/municipality-services.service';
import { MunicipalityWastePickupsService } from '../src/municipality/waste-pickups/municipality-waste-pickups.service';
import { TenantSettingsService } from '../src/municipality/tenant-settings/tenant-settings.service';
import { ActivationCodesService } from '../src/auth/activation-codes.service';
import { ResidentsService } from '../src/auth/residents.service';
import { TenantConfigService as TenantProfileService } from '../src/tenant/tenant.service';

const tenantId = process.argv[2];
if (!tenantId) {
  // eslint-disable-next-line no-console
  console.error('Usage: npm run seed:tenant -- <tenantId>');
  process.exit(1);
}

const DEFAULT_FEATURE_FLAGS: Record<string, boolean> = {
  events: true,
  posts: true,
  warnings: true,
  services: true,
  places: true,
  clubs: true,
  waste: true,
};

const bootstrapTenant = async () => {
  const tenantSettingsService = new TenantSettingsService();
  const tenantProfileService = new TenantProfileService();
  const residentsService = new ResidentsService();
  const activationCodesService = new ActivationCodesService();

  const existingSettings = await tenantSettingsService.getSettings(tenantId);
  const mergedFlags = {
    ...DEFAULT_FEATURE_FLAGS,
    ...(existingSettings.featureFlagsJson ?? {}),
  };

  await tenantSettingsService.upsertSettings(tenantId, {
    featureFlagsJson: mergedFlags,
    brandingJson: existingSettings.brandingJson ?? {},
    openingHoursJson: existingSettings.openingHoursJson ?? [],
  });

  await tenantProfileService.getConfig(tenantId);

  const eventsService = new MunicipalityEventsService();
  const postsService = new MunicipalityPostsService();
  const servicesService = new MunicipalityServicesService();
  const placesService = new MunicipalityPlacesService();
  const clubsService = new MunicipalityClubsService();
  const wasteService = new MunicipalityWastePickupsService();

  await eventsService.list(tenantId, {});
  await postsService.list(tenantId, { now: new Date() });
  await servicesService.list(tenantId, {});
  await placesService.list(tenantId, {});
  await clubsService.list(tenantId, {});
  await wasteService.bulkUpsert(tenantId, []);

  if (tenantId === 'hilders') {
    const residents = [
      {
        firstName: 'Florian',
        lastName: 'Günkel',
        postalCode: '36115',
        houseNumber: '5',
      },
      {
        firstName: 'Erika',
        lastName: 'Musterfrau',
        postalCode: '36115',
        houseNumber: '7',
      },
    ];

    const codes: Array<{ name: string; code: string; expiresAt: string }> = [];
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    for (const residentPayload of residents) {
      const existing = await residentsService.findByIdentity(
        tenantId,
        residentPayload,
      );
      const resident = existing
        ? await residentsService.update(tenantId, existing.id, residentPayload)
        : await residentsService.create(tenantId, residentPayload);

      const { code, activation } = await activationCodesService.createCode(
        tenantId,
        resident.id,
        expiresAt,
      );
      codes.push({
        name: `${resident.firstName} ${resident.lastName}`,
        code,
        expiresAt: activation.expiresAt,
      });
    }

    if (process.env.NODE_ENV !== 'production') {
      for (const entry of codes) {
        // eslint-disable-next-line no-console
        console.log(
          `Activation code for ${entry.name}: ${entry.code} (expires ${entry.expiresAt})`,
        );
      }
    }
  }

  // eslint-disable-next-line no-console
  console.log(`Tenant ${tenantId} seeded successfully.`);
};

bootstrapTenant().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
