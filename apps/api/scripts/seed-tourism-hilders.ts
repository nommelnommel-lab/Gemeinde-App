import { TourismService } from '../src/tourism/tourism.service';
import { tourismSeedItems } from '../src/tourism/tourism-seed-hilders.data';

const tenantId = process.env.TENANT ?? 'hilders-demo';

const seed = async () => {
  const tourismService = new TourismService();
  await tourismService.seedDemo(tenantId, tourismSeedItems);

  // eslint-disable-next-line no-console
  console.log(`Seeded tourism demo data for ${tenantId}.`);
};

seed().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
