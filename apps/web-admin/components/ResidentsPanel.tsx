'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';
import ResidentsTable from './ResidentsTable';
import CreateResidentModal from './CreateResidentModal';

type Resident = {
  id: string;
  displayName: string;
  postalCode: string;
  houseNumber: string;
  status: string;
  createdAt: string;
};

type FilterState = {
  q: string;
  postalCode: string;
  houseNumber: string;
  status: string;
};

const defaultFilters: FilterState = {
  q: '',
  postalCode: '',
  houseNumber: '',
  status: '',
};

const buildQuery = (filters: FilterState) => {
  const params = new URLSearchParams();
  if (filters.q) {
    params.set('q', filters.q);
  }
  if (filters.postalCode) {
    params.set('postalCode', filters.postalCode);
  }
  if (filters.houseNumber) {
    params.set('houseNumber', filters.houseNumber);
  }
  if (filters.status) {
    params.set('status', filters.status);
  }
  return params.toString();
};

export default function ResidentsPanel() {
  const [filters, setFilters] = useState<FilterState>(defaultFilters);
  const [residents, setResidents] = useState<Resident[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [showModal, setShowModal] = useState(false);

  const loadResidents = async (activeFilters = filters) => {
    setLoading(true);
    setError(null);
    try {
      const query = buildQuery(activeFilters);
      const data = await apiFetch<Resident[]>(
        `/api/admin/residents${query ? `?${query}` : ''}`,
      );
      setResidents(data ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadResidents();
  }, []);

  return (
    <div className="stack">
      <div className="row">
        <div className="field">
          <label htmlFor="search">Suche</label>
          <input
            id="search"
            placeholder="Name"
            value={filters.q}
            onChange={(event) =>
              setFilters({ ...filters, q: event.target.value })
            }
          />
        </div>
        <div className="field">
          <label htmlFor="postalCode">PLZ</label>
          <input
            id="postalCode"
            value={filters.postalCode}
            onChange={(event) =>
              setFilters({ ...filters, postalCode: event.target.value })
            }
          />
        </div>
        <div className="field">
          <label htmlFor="houseNumber">Hausnummer</label>
          <input
            id="houseNumber"
            value={filters.houseNumber}
            onChange={(event) =>
              setFilters({ ...filters, houseNumber: event.target.value })
            }
          />
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select
            id="status"
            value={filters.status}
            onChange={(event) =>
              setFilters({ ...filters, status: event.target.value })
            }
          >
            <option value="">Alle</option>
            <option value="ACTIVE">Aktiv</option>
            <option value="INACTIVE">Inaktiv</option>
          </select>
        </div>
      </div>
      <div className="row">
        <button type="button" onClick={() => loadResidents(filters)}>
          Suchen
        </button>
        <button
          type="button"
          className="secondary"
          onClick={() => {
            setFilters(defaultFilters);
            loadResidents(defaultFilters);
          }}
        >
          Filter zurücksetzen
        </button>
        <button type="button" onClick={() => setShowModal(true)}>
          Bewohner anlegen
        </button>
      </div>
      {error && <ErrorNotice error={error} />}
      {loading ? (
        <LoadingState />
      ) : (
        <ResidentsTable residents={residents} />
      )}
      {showModal && (
        <CreateResidentModal
          onClose={() => setShowModal(false)}
          onCreated={() => loadResidents(filters)}
        />
      )}
    </div>
  );
}
