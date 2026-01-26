import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { TenantFileRepository } from '../storage/tenant-file.repository';
import {
  MunicipalityFormLink,
  MunicipalityFormLinkInput,
} from './municipality-forms.types';

@Injectable()
export class MunicipalityFormsService {
  private readonly repository = new TenantFileRepository<MunicipalityFormLink>(
    'forms',
  );

  async list(
    tenantId: string,
    options?: { category?: string },
  ): Promise<MunicipalityFormLink[]> {
    const forms = await this.repository.getAll(tenantId);
    if (options?.category) {
      const category = options.category.toLowerCase();
      return forms.filter((form) => form.category.toLowerCase() === category);
    }
    return forms;
  }

  async upsertMany(
    tenantId: string,
    inputs: MunicipalityFormLinkInput[],
  ): Promise<MunicipalityFormLink[]> {
    const forms = await this.repository.getAll(tenantId);
    const now = new Date().toISOString();
    const byUrl = new Map(inputs.map((entry) => [entry.url, entry]));
    const existingByUrl = new Map(
      forms.map((entry) => [entry.url, entry]),
    );

    const updatedForms = forms.map((form) => {
      const incoming = byUrl.get(form.url);
      if (!incoming) {
        return form;
      }

      const updated: MunicipalityFormLink = {
        ...form,
        category: incoming.category,
        title: incoming.title,
        url: incoming.url,
        updatedAt: now,
      };
      existingByUrl.set(form.url, updated);
      return updated;
    });

    for (const [url, input] of byUrl) {
      if (existingByUrl.has(url)) {
        continue;
      }
      updatedForms.push({
        id: randomUUID(),
        tenantId,
        category: input.category,
        title: input.title,
        url: input.url,
        createdAt: now,
        updatedAt: now,
      });
    }

    await this.repository.setAll(tenantId, updatedForms);
    return updatedForms;
  }
}
