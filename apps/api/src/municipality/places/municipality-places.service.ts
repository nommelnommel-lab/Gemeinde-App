import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  MunicipalityPlace,
  MunicipalityPlaceInput,
  MunicipalityPlacePatch,
  PlaceStatus,
} from './municipality-places.types';

@Injectable()
export class MunicipalityPlacesService {
  private readonly repository = new TenantFileRepository<MunicipalityPlace>(
    'places',
    (tenantId) => this.createSeedPlaces(tenantId),
  );

  async list(
    tenantId: string,
    options: {
      type?: string;
      status?: PlaceStatus;
      bbox?: { minLon: number; minLat: number; maxLon: number; maxLat: number };
    },
  ): Promise<MunicipalityPlace[]> {
    const status = options.status ?? 'PUBLISHED';
    const places = await this.repository.getAll(tenantId);
    return places.filter((place) => {
      if (place.status !== status) {
        return false;
      }
      if (options.type && place.type !== options.type) {
        return false;
      }
      if (options.bbox && place.lat !== undefined && place.lon !== undefined) {
        const { minLon, minLat, maxLon, maxLat } = options.bbox;
        if (
          place.lon < minLon ||
          place.lon > maxLon ||
          place.lat < minLat ||
          place.lat > maxLat
        ) {
          return false;
        }
      }
      return true;
    });
  }

  async getById(tenantId: string, id: string): Promise<MunicipalityPlace> {
    const places = await this.repository.getAll(tenantId);
    const place = places.find((item) => item.id === id);
    if (!place) {
      throw new NotFoundException('Ort nicht gefunden');
    }
    return place;
  }

  async create(
    tenantId: string,
    input: MunicipalityPlaceInput,
  ): Promise<MunicipalityPlace> {
    const places = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const place: MunicipalityPlace = {
      id: randomUUID(),
      tenantId,
      name: input.name,
      description: input.description,
      type: input.type,
      address: input.address,
      lat: input.lat,
      lon: input.lon,
      status: input.status ?? 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    };
    places.push(place);
    await this.repository.setAll(tenantId, places);
    return place;
  }

  async update(
    tenantId: string,
    id: string,
    patch: MunicipalityPlacePatch,
  ): Promise<MunicipalityPlace> {
    const places = await this.repository.getAll(tenantId);
    const index = places.findIndex((place) => place.id === id);
    if (index === -1) {
      throw new NotFoundException('Ort nicht gefunden');
    }

    const updated: MunicipalityPlace = {
      ...places[index],
      name: patch.name ?? places[index].name,
      description: patch.description ?? places[index].description,
      type: patch.type ?? places[index].type,
      address: patch.address ?? places[index].address,
      lat: patch.lat ?? places[index].lat,
      lon: patch.lon ?? places[index].lon,
      status: patch.status ?? places[index].status,
      updatedAt: new Date().toISOString(),
    };

    places[index] = updated;
    await this.repository.setAll(tenantId, places);
    return updated;
  }

  async archive(tenantId: string, id: string): Promise<void> {
    const places = await this.repository.getAll(tenantId);
    const index = places.findIndex((place) => place.id === id);
    if (index === -1) {
      throw new NotFoundException('Ort nicht gefunden');
    }

    places[index] = {
      ...places[index],
      status: 'ARCHIVED',
      updatedAt: new Date().toISOString(),
    };
    await this.repository.setAll(tenantId, places);
  }

  private createSeedPlaces(tenantId: string): MunicipalityPlace[] {
    if (tenantId !== 'hilders') {
      return [];
    }

    const now = new Date().toISOString();
    const createPlace = (
      name: string,
      description: string,
      type: string,
      lat: number,
      lon: number,
      address?: string,
    ): MunicipalityPlace => ({
      id: randomUUID(),
      tenantId,
      name,
      description,
      type,
      address,
      lat,
      lon,
      status: 'PUBLISHED',
      createdAt: now,
      updatedAt: now,
    });

    return [
      createPlace(
        'Spielplatz Marktstraße',
        'Spielplatz mit Klettergerüst.',
        'playground',
        50.5712,
        9.9894,
        'Marktstraße 12',
      ),
      createPlace(
        'Spielplatz Ulsterweg',
        'Rutsche, Sandkasten und Sitzbank.',
        'playground',
        50.5751,
        9.9784,
        'Ulsterweg 5',
      ),
      createPlace(
        'Defibrillator Rathaus',
        'Defibrillator im Eingangsbereich.',
        'defibrillator',
        50.5718,
        9.9931,
        'Marktstraße 2',
      ),
      createPlace(
        'Defibrillator Bürgerhaus',
        'AED im Foyer.',
        'defibrillator',
        50.5692,
        9.9811,
        'Bahnhofstraße 8',
      ),
      createPlace(
        'Parkplatz Ortsmitte',
        'Zentrale Parkmöglichkeit nahe Rathaus.',
        'parking',
        50.571,
        9.9912,
        'Parkplatz Rathaus',
      ),
      createPlace(
        'Parkplatz Milseburg',
        'Ausgangspunkt für Wanderungen.',
        'parking',
        50.527,
        9.9815,
        'Milseburgstraße 1',
      ),
      createPlace(
        'Tourist-Information',
        'Infos zu Wanderwegen und Veranstaltungen.',
        'poi',
        50.5723,
        9.9918,
        'Marktstraße 4',
      ),
      createPlace(
        'Bürgerhaus Hilders',
        'Veranstaltungsort der Gemeinde.',
        'poi',
        50.5684,
        9.9825,
        'Bahnhofstraße 8',
      ),
      createPlace(
        'Wassertretbecken',
        'Kneippbecken am Ulsterweg.',
        'poi',
        50.5765,
        9.9762,
        'Ulsterweg',
      ),
      createPlace(
        'E-Ladestation Marktstraße',
        'Ladesäule mit zwei Stellplätzen.',
        'poi',
        50.5719,
        9.9924,
        'Marktstraße 6',
      ),
    ];
  }
}
