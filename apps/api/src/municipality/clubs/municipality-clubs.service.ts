import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  ClubStatus,
  MunicipalityClub,
  MunicipalityClubInput,
  MunicipalityClubPatch,
} from './municipality-clubs.types';

@Injectable()
export class MunicipalityClubsService {
  private readonly repository = new TenantFileRepository<MunicipalityClub>(
    'clubs',
    (tenantId) => this.createSeedClubs(tenantId),
  );

  async list(
    tenantId: string,
    options: { query?: string; status?: ClubStatus },
  ): Promise<MunicipalityClub[]> {
    const status = options.status ?? 'PUBLISHED';
    const clubs = await this.repository.getAll(tenantId);
    return clubs.filter((club) => {
      if (club.status !== status) {
        return false;
      }
      if (options.query) {
        const q = options.query.toLowerCase();
        return (
          club.name.toLowerCase().includes(q) ||
          club.description.toLowerCase().includes(q)
        );
      }
      return true;
    });
  }

  async getById(tenantId: string, id: string): Promise<MunicipalityClub> {
    const clubs = await this.repository.getAll(tenantId);
    const club = clubs.find((item) => item.id === id);
    if (!club) {
      throw new NotFoundException('Verein nicht gefunden');
    }
    return club;
  }

  async create(
    tenantId: string,
    input: MunicipalityClubInput,
  ): Promise<MunicipalityClub> {
    const clubs = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const club: MunicipalityClub = {
      id: randomUUID(),
      tenantId,
      name: input.name,
      description: input.description,
      contactName: input.contactName,
      email: input.email,
      phone: input.phone,
      website: input.website,
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };
    clubs.push(club);
    await this.repository.setAll(tenantId, clubs);
    return club;
  }

  async update(
    tenantId: string,
    id: string,
    patch: MunicipalityClubPatch,
  ): Promise<MunicipalityClub> {
    const clubs = await this.repository.getAll(tenantId);
    const index = clubs.findIndex((club) => club.id === id);
    if (index === -1) {
      throw new NotFoundException('Verein nicht gefunden');
    }

    const updated: MunicipalityClub = {
      ...clubs[index],
      name: patch.name ?? clubs[index].name,
      description: patch.description ?? clubs[index].description,
      contactName: patch.contactName ?? clubs[index].contactName,
      email: patch.email ?? clubs[index].email,
      phone: patch.phone ?? clubs[index].phone,
      website: patch.website ?? clubs[index].website,
      status: patch.status ?? clubs[index].status,
      updatedAt: new Date().toISOString(),
    };

    clubs[index] = updated;
    await this.repository.setAll(tenantId, clubs);
    return updated;
  }

  async archive(tenantId: string, id: string): Promise<void> {
    const clubs = await this.repository.getAll(tenantId);
    const index = clubs.findIndex((club) => club.id === id);
    if (index === -1) {
      throw new NotFoundException('Verein nicht gefunden');
    }

    clubs[index] = {
      ...clubs[index],
      status: 'ARCHIVED',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, clubs);
  }

  private createSeedClubs(tenantId: string): MunicipalityClub[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date().toISOString();
    const createClub = (
      name: string,
      description: string,
      contactName: string,
    ): MunicipalityClub => ({
      id: randomUUID(),
      tenantId,
      name,
      description,
      contactName,
      email: `${name.toLowerCase().replace(/\s+/g, '')}@hilders.de`,
      phone: '+49 6681 9605-0',
      status: 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    });

    return [
      createClub('SV Hilders', 'Sportverein für Fußball und Turnen.', 'Lisa Koch'),
      createClub('Rhöner Musikfreunde', 'Blasorchester mit Proberaum im Bürgerhaus.', 'Tobias Lang'),
      createClub('Feuerwehrverein Hilders', 'Unterstützt die Freiwillige Feuerwehr.', 'Martin Vogt'),
      createClub('Heimat- und Verkehrsverein', 'Engagiert für Tourismus und Tradition.', 'Petra Braun'),
      createClub('Jugendclub Ulstertal', 'Freizeitangebote für Jugendliche.', 'Nina Stein'),
    ];
  }
}
