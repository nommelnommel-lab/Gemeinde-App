'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type TourismItemType = 'HIKING_ROUTE' | 'SIGHT' | 'LEISURE' | 'RESTAURANT';
type TourismItemStatus = 'PUBLISHED' | 'HIDDEN';

type TourismItemEntity = {
  id: string;
  type: TourismItemType;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
  status: TourismItemStatus;
  createdAt: string;
  updatedAt: string;
};

type TourismFormState = {
  title: string;
  body: string;
  status: TourismItemStatus;
  metadata: {
    address: string;
    phone: string;
    url: string;
  };
};

const sections: Array<{ type: TourismItemType; label: string }> = [
  { type: 'HIKING_ROUTE', label: 'Wanderrouten' },
  { type: 'SIGHT', label: 'Sehenswürdigkeiten' },
  { type: 'LEISURE', label: 'Freizeitangebote' },
  { type: 'RESTAURANT', label: 'Restaurants' },
];

const statusOptions: TourismItemStatus[] = ['PUBLISHED', 'HIDDEN'];

const createEmptyForm = (): TourismFormState => ({
  title: '',
  body: '',
  status: 'PUBLISHED',
  metadata: {
    address: '',
    phone: '',
    url: '',
  },
});

const createRecord = <T,>(factory: () => T) =>
  sections.reduce(
    (accumulator, section) => ({
      ...accumulator,
      [section.type]: factory(),
    }),
    {} as Record<TourismItemType, T>,
  );

const extractMetadataValue = (metadata: Record<string, unknown> | undefined, key: string) => {
  if (!metadata || !(key in metadata)) {
    return '';
  }
  const value = metadata[key];
  return typeof value === 'string' ? value : String(value ?? '');
};

export default function TourismPanel() {
  const [activeType, setActiveType] = useState<TourismItemType>('HIKING_ROUTE');
  const [itemsByType, setItemsByType] = useState<Record<TourismItemType, TourismItemEntity[]>>(
    () => createRecord(() => []),
  );
  const [searchByType, setSearchByType] = useState<Record<TourismItemType, string>>(
    () => createRecord(() => ''),
  );
  const [formByType, setFormByType] = useState<Record<TourismItemType, TourismFormState>>(
    () => createRecord(createEmptyForm),
  );
  const [editingByType, setEditingByType] = useState<
    Record<TourismItemType, TourismItemEntity | null>
  >(() => createRecord(() => null));

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const activeForm = formByType[activeType];
  const activeEditing = editingByType[activeType];

  const loadItems = async (type: TourismItemType) => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ type });
      const data = await apiFetch<TourismItemEntity[]>(
        `/api/admin/tourism?${params.toString()}`,
      );
      setItemsByType((prev) => ({ ...prev, [type]: data ?? [] }));
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadItems(activeType);
  }, [activeType]);

  const filteredItems = useMemo(() => {
    const search = searchByType[activeType].toLowerCase();
    return itemsByType[activeType].filter((item) =>
      item.title.toLowerCase().includes(search),
    );
  }, [activeType, itemsByType, searchByType]);

  const updateForm = (updates: Partial<TourismFormState>) => {
    setFormByType((prev) => ({
      ...prev,
      [activeType]: { ...prev[activeType], ...updates },
    }));
  };

  const updateMetadata = (field: keyof TourismFormState['metadata'], value: string) => {
    setFormByType((prev) => ({
      ...prev,
      [activeType]: {
        ...prev[activeType],
        metadata: {
          ...prev[activeType].metadata,
          [field]: value,
        },
      },
    }));
  };

  const buildMetadataPayload = (form: TourismFormState) => {
    const metadata: Record<string, string> = {};
    const address = form.metadata.address.trim();
    const phone = form.metadata.phone.trim();
    const url = form.metadata.url.trim();
    if (address) {
      metadata.address = address;
    }
    if (phone) {
      metadata.phone = phone;
    }
    if (url) {
      metadata.url = url;
    }
    return metadata;
  };

  const resetForm = (type: TourismItemType) => {
    setFormByType((prev) => ({ ...prev, [type]: createEmptyForm() }));
    setEditingByType((prev) => ({ ...prev, [type]: null }));
  };

  const saveItem = async () => {
    setLoading(true);
    setError(null);
    try {
      const payload = {
        type: activeType,
        title: activeForm.title.trim(),
        body: activeForm.body.trim(),
        metadata: buildMetadataPayload(activeForm),
        status: activeForm.status,
      };
      if (activeEditing) {
        await apiFetch(`/api/admin/tourism/${activeEditing.id}`, {
          method: 'PATCH',
          body: JSON.stringify(payload),
        });
      } else {
        await apiFetch('/api/admin/tourism', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      resetForm(activeType);
      await loadItems(activeType);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const hideItem = async (item: TourismItemEntity) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/tourism/${item.id}`, { method: 'DELETE' });
      await loadItems(activeType);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const unhideItem = async (item: TourismItemEntity) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/tourism/${item.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: 'PUBLISHED' }),
      });
      await loadItems(activeType);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="stack">
      <div className="tabs">
        {sections.map((section) => (
          <button
            key={section.type}
            type="button"
            className={`tab ${activeType === section.type ? 'active' : ''}`}
            onClick={() => setActiveType(section.type)}
          >
            {section.label}
          </button>
        ))}
      </div>

      {error && <ErrorNotice error={error} />}
      {loading && <LoadingState />}

      <div className="stack">
        <div className="card stack">
          <h3>
            {activeEditing
              ? `${sections.find((section) => section.type === activeType)?.label} bearbeiten`
              : `${sections.find((section) => section.type === activeType)?.label} erstellen`}
          </h3>
          <div className="row">
            <div className="field">
              <label htmlFor="tourismTitle">Titel</label>
              <input
                id="tourismTitle"
                value={activeForm.title}
                onChange={(event) => updateForm({ title: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="tourismStatus">Status</label>
              <select
                id="tourismStatus"
                value={activeForm.status}
                onChange={(event) =>
                  updateForm({ status: event.target.value as TourismItemStatus })
                }
              >
                {statusOptions.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="field">
            <label htmlFor="tourismBody">Beschreibung</label>
            <textarea
              id="tourismBody"
              rows={4}
              value={activeForm.body}
              onChange={(event) => updateForm({ body: event.target.value })}
            />
          </div>
          <div className="row">
            <div className="field">
              <label htmlFor="tourismAddress">Adresse (optional)</label>
              <input
                id="tourismAddress"
                value={activeForm.metadata.address}
                onChange={(event) => updateMetadata('address', event.target.value)}
              />
            </div>
            <div className="field">
              <label htmlFor="tourismPhone">Telefon (optional)</label>
              <input
                id="tourismPhone"
                value={activeForm.metadata.phone}
                onChange={(event) => updateMetadata('phone', event.target.value)}
              />
            </div>
            <div className="field">
              <label htmlFor="tourismUrl">URL (optional)</label>
              <input
                id="tourismUrl"
                value={activeForm.metadata.url}
                onChange={(event) => updateMetadata('url', event.target.value)}
              />
            </div>
          </div>
          <div className="row">
            <button type="button" onClick={saveItem}>
              {activeEditing ? 'Änderungen speichern' : 'Eintrag anlegen'}
            </button>
            {activeEditing && (
              <button
                type="button"
                className="secondary"
                onClick={() => resetForm(activeType)}
              >
                Abbrechen
              </button>
            )}
          </div>
        </div>

        <div className="card stack">
          <div className="row">
            <div className="field">
              <label htmlFor="tourismSearch">Suche</label>
              <input
                id="tourismSearch"
                value={searchByType[activeType]}
                onChange={(event) =>
                  setSearchByType((prev) => ({
                    ...prev,
                    [activeType]: event.target.value,
                  }))
                }
              />
            </div>
            <button type="button" onClick={() => loadItems(activeType)}>
              Aktualisieren
            </button>
          </div>
          {filteredItems.length === 0 ? (
            <p>Keine Einträge gefunden.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Titel</th>
                    <th>Status</th>
                    <th>Aktionen</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredItems.map((item) => (
                    <tr key={item.id}>
                      <td>{item.title}</td>
                      <td>{item.status}</td>
                      <td className="row">
                        <button
                          type="button"
                          className="secondary"
                          onClick={() => {
                            setEditingByType((prev) => ({
                              ...prev,
                              [activeType]: item,
                            }));
                            setFormByType((prev) => ({
                              ...prev,
                              [activeType]: {
                                title: item.title,
                                body: item.body,
                                status: item.status,
                                metadata: {
                                  address: extractMetadataValue(item.metadata, 'address'),
                                  phone: extractMetadataValue(item.metadata, 'phone'),
                                  url: extractMetadataValue(item.metadata, 'url'),
                                },
                              },
                            }));
                          }}
                        >
                          Bearbeiten
                        </button>
                        {item.status === 'HIDDEN' ? (
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => unhideItem(item)}
                          >
                            Einblenden
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => hideItem(item)}
                          >
                            Ausblenden
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
