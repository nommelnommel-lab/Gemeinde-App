import { promises as fs } from 'fs';
import { join } from 'path';

const DATA_DIR = join(process.cwd(), 'data', 'tenants');

const migrateTenant = async (tenantId: string) => {
  const filePath = join(DATA_DIR, tenantId, 'users.json');
  try {
    const raw = await fs.readFile(filePath, 'utf8');
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return;
    }
    let updated = false;
    const migrated = parsed.map((user) => {
      if (user && typeof user === 'object' && !user.role) {
        updated = true;
        return {
          ...user,
          role: 'USER',
          updatedAt: new Date().toISOString(),
        };
      }
      return user;
    });
    if (updated) {
      await fs.writeFile(filePath, JSON.stringify(migrated, null, 2), 'utf8');
      // eslint-disable-next-line no-console
      console.log(`Updated roles in ${tenantId}/users.json`);
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn(`Skipping ${tenantId}: ${(error as Error).message}`);
  }
};

const main = async () => {
  try {
    const tenants = await fs.readdir(DATA_DIR);
    await Promise.all(tenants.map((tenant) => migrateTenant(tenant)));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(`Migration failed: ${(error as Error).message}`);
    process.exit(1);
  }
};

void main();
