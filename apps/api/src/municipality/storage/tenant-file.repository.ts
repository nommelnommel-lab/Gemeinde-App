import { promises as fs } from 'fs';
import { dirname, join } from 'node:path';

export type TenantSeedProvider<T> = (tenantId: string) => T[];

export class TenantFileRepository<T> {
  private readonly cache = new Map<string, T[]>();

  constructor(
    private readonly resourceName: string,
    private readonly seedProvider?: TenantSeedProvider<T>,
  ) {}

  async getAll(tenantId: string): Promise<T[]> {
    const cached = this.cache.get(tenantId);
    if (cached) {
      return [...cached];
    }

    const filePath = this.getFilePath(tenantId);
    await this.ensureDirectory(filePath);

    try {
      const file = await fs.readFile(filePath, 'utf8');
      const parsed = JSON.parse(file);
      const items = Array.isArray(parsed) ? (parsed as T[]) : [];
      this.cache.set(tenantId, items);
      return [...items];
    } catch {
      const seeded = this.seedProvider ? this.seedProvider(tenantId) : [];
      await this.writeFileAtomic(filePath, seeded);
      this.cache.set(tenantId, seeded);
      return [...seeded];
    }
  }

  async setAll(tenantId: string, items: T[]): Promise<void> {
    const filePath = this.getFilePath(tenantId);
    await this.ensureDirectory(filePath);
    this.cache.set(tenantId, items);
    await this.writeFileAtomic(filePath, items);
  }

  private getFilePath(tenantId: string) {
    return join(
      process.cwd(),
      'data',
      'tenants',
      tenantId,
      `${this.resourceName}.json`,
    );
  }

  private async ensureDirectory(filePath: string) {
    const directory = dirname(filePath);
    await fs.mkdir(directory, { recursive: true });
  }

  private async writeFileAtomic(filePath: string, data: T[]) {
    const tempPath = `${filePath}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, filePath);
  }
}
