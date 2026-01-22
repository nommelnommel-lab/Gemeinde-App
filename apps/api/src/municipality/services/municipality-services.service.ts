import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  MunicipalityService,
  MunicipalityServiceInput,
  MunicipalityServicePatch,
  ServiceStatus,
} from './municipality-services.types';

@Injectable()
export class MunicipalityServicesService {
  private readonly repository = new TenantFileRepository<MunicipalityService>(
    'services',
    (tenantId) => this.createSeedServices(tenantId),
  );

  async list(
    tenantId: string,
    options: {
      query?: string;
      status?: ServiceStatus;
      limit?: number;
    },
  ): Promise<MunicipalityService[]> {
    const status = options.status ?? 'PUBLISHED';
    const services = await this.repository.getAll(tenantId);
    const filtered = services.filter((service) => {
      if (service.status !== status) {
        return false;
      }
      if (options.query) {
        const q = options.query.toLowerCase();
        return (
          service.name.toLowerCase().includes(q) ||
          service.description.toLowerCase().includes(q) ||
          service.category?.toLowerCase().includes(q)
        );
      }
      return true;
    });

    if (options.limit) {
      return filtered.slice(0, options.limit);
    }
    return filtered;
  }

  async listFeatured(
    tenantId: string,
    limit = 6,
  ): Promise<MunicipalityService[]> {
    const services = await this.repository.getAll(tenantId);
    const featured = services.filter(
      (service) => service.status === 'PUBLISHED' && service.featured,
    );
    return featured.slice(0, limit);
  }

  async getById(tenantId: string, id: string): Promise<MunicipalityService> {
    const services = await this.repository.getAll(tenantId);
    const service = services.find((item) => item.id === id);
    if (!service) {
      throw new NotFoundException('Service nicht gefunden');
    }
    return service;
  }

  async create(
    tenantId: string,
    input: MunicipalityServiceInput,
  ): Promise<MunicipalityService> {
    const services = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const service: MunicipalityService = {
      id: randomUUID(),
      tenantId,
      name: input.name,
      description: input.description,
      category: input.category,
      url: input.url,
      featured: input.featured ?? false,
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };
    services.push(service);
    await this.repository.setAll(tenantId, services);
    return service;
  }

  async update(
    tenantId: string,
    id: string,
    patch: MunicipalityServicePatch,
  ): Promise<MunicipalityService> {
    const services = await this.repository.getAll(tenantId);
    const index = services.findIndex((service) => service.id === id);
    if (index === -1) {
      throw new NotFoundException('Service nicht gefunden');
    }

    const updated: MunicipalityService = {
      ...services[index],
      name: patch.name ?? services[index].name,
      description: patch.description ?? services[index].description,
      category: patch.category ?? services[index].category,
      url: patch.url ?? services[index].url,
      featured: patch.featured ?? services[index].featured,
      status: patch.status ?? services[index].status,
      updatedAt: new Date().toISOString(),
    };

    services[index] = updated;
    await this.repository.setAll(tenantId, services);
    return updated;
  }

  async archive(tenantId: string, id: string): Promise<void> {
    const services = await this.repository.getAll(tenantId);
    const index = services.findIndex((service) => service.id === id);
    if (index === -1) {
      throw new NotFoundException('Service nicht gefunden');
    }

    services[index] = {
      ...services[index],
      status: 'ARCHIVED',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, services);
  }

  private createSeedServices(tenantId: string): MunicipalityService[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date().toISOString();
    const createService = (
      name: string,
      description: string,
      category: string,
      featured = false,
      url?: string,
    ): MunicipalityService => ({
      id: randomUUID(),
      tenantId,
      name,
      description,
      category,
      url,
      featured,
      status: 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    });

    return [
      createService(
        'Hundeanmeldung',
        'Online-Formular zur Anmeldung eines Hundes.',
        'Steuern',
        true,
        'https://www.hilders.de/hundeanmeldung',
      ),
      createService(
        'Sperrmüll anmelden',
        'Terminvereinbarung für die Sperrmüllabholung.',
        'Abfall',
        true,
        'https://www.hilders.de/sperrmuell',
      ),
      createService(
        'Fundbüro',
        'Fundstücke melden oder abholen.',
        'Bürgerservice',
        false,
        'https://www.hilders.de/fundbuero',
      ),
      createService(
        'Personalausweis beantragen',
        'Hinweise und Unterlagen für den neuen Ausweis.',
        'Bürgerbüro',
        false,
        'https://www.hilders.de/personalausweis',
      ),
      createService(
        'Gewerbe anmelden',
        'Formular für Gewerbean- und abmeldung.',
        'Wirtschaft',
        false,
        'https://www.hilders.de/gewerbe',
      ),
      createService(
        'Kinderbetreuung',
        'Anmeldung für Krippe und Kindergarten.',
        'Familie',
        false,
        'https://www.hilders.de/kinderbetreuung',
      ),
      createService(
        'Bauantrag einreichen',
        'Checkliste und Upload für Bauanträge.',
        'Bauen',
        false,
        'https://www.hilders.de/bauantrag',
      ),
      createService(
        'Mängelmelder',
        'Schäden an Straßen oder Laternen melden.',
        'Service',
        false,
        'https://www.hilders.de/maengelmelder',
      ),
    ];
  }
}
