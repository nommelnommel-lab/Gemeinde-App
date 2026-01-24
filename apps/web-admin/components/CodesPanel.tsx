'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';
import { buildCsv, downloadCsv } from '../lib/csv';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';
import ResidentsTable from './ResidentsTable';

type Resident = {
  id: string;
  displayName: string;
  postalCode: string;
  houseNumber: string;
  status: string;
  createdAt: string;
};

type BulkResponse = {
  created: Array<{ residentId: string; code: string; expiresAt: string }>;
  skipped: Array<{ residentId: string; reason: string }>;
};

type CodeResult = {
  residentId: string;
  displayName: string;
  postalCode: string;
  houseNumber: string;
  activationCode: string;
  expiresAt: string;
};

const buildQuery = (
  q: string,
  postalCode: string,
  houseNumber: string,
) => {
  const params = new URLSearchParams();
  if (q) {
    params.set('q', q);
  }
  if (postalCode) {
    params.set('postalCode', postalCode);
  }
  if (houseNumber) {
    params.set('houseNumber', houseNumber);
  }
  return params.toString();
};

export default function CodesPanel() {
  const [q, setQ] = useState('');
  const [postalCode, setPostalCode] = useState('');
  const [houseNumber, setHouseNumber] = useState('');
  const [residents, setResidents] = useState<Resident[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [expiresInDays, setExpiresInDays] = useState('30');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [results, setResults] = useState<BulkResponse | null>(null);
  const [copyStatus, setCopyStatus] = useState<string | null>(null);

  const loadResidents = async () => {
    setLoading(true);
    setError(null);
    try {
      const query = buildQuery(q, postalCode, houseNumber);
      const data = await apiFetch<Resident[]>(
        `/api/admin/residents${query ? `?${query}` : ''}`,
      );
      setResidents(data ?? []);
      setSelected(new Set());
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadResidents();
  }, []);

  const toggleResident = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const generateCodes = async () => {
    setLoading(true);
    setError(null);
    setResults(null);
    setCopyStatus(null);

    try {
      const parsedExpires = Number.parseInt(expiresInDays, 10);
      const payload = {
        residentIds: Array.from(selected),
        ...(Number.isFinite(parsedExpires) ? { expiresInDays: parsedExpires } : {}),
      };
      const response = await apiFetch<BulkResponse>(
        '/api/admin/activation-codes/bulk',
        {
          method: 'POST',
          body: JSON.stringify(payload),
        },
      );
      setResults(response);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const codes = useMemo(() => {
    if (!results) {
      return [];
    }
    const residentMap = new Map(residents.map((resident) => [resident.id, resident]));
    return results.created.map((entry) => {
      const resident = residentMap.get(entry.residentId);
      return {
        residentId: entry.residentId,
        displayName: resident?.displayName ?? 'Unbekannt',
        postalCode: resident?.postalCode ?? '',
        houseNumber: resident?.houseNumber ?? '',
        activationCode: entry.code,
        expiresAt: entry.expiresAt,
      };
    });
  }, [results, residents]);

  const exportCsv = () => {
    const csv = buildCsv(
      ['displayName', 'postalCode', 'houseNumber', 'activationCode', 'expiresAt'],
      codes.map((entry) => [
        entry.displayName,
        entry.postalCode,
        entry.houseNumber,
        entry.activationCode,
        entry.expiresAt,
      ]),
    );
    downloadCsv('activation-codes.csv', csv);
  };

  const copyCsv = async () => {
    const csv = buildCsv(
      ['displayName', 'postalCode', 'houseNumber', 'activationCode', 'expiresAt'],
      codes.map((entry) => [
        entry.displayName,
        entry.postalCode,
        entry.houseNumber,
        entry.activationCode,
        entry.expiresAt,
      ]),
    );
    try {
      await navigator.clipboard.writeText(csv);
      setCopyStatus('CSV wurde in die Zwischenablage kopiert.');
    } catch {
      setCopyStatus('Kopieren fehlgeschlagen. Bitte CSV herunterladen.');
    }
  };

  return (
    <div className="stack">
      <div className="row">
        <div className="field">
          <label htmlFor="search">Suche</label>
          <input
            id="search"
            value={q}
            onChange={(event) => setQ(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="postalCode">PLZ</label>
          <input
            id="postalCode"
            value={postalCode}
            onChange={(event) => setPostalCode(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="houseNumber">Hausnummer</label>
          <input
            id="houseNumber"
            value={houseNumber}
            onChange={(event) => setHouseNumber(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="expiresInDays">Gültigkeit (Tage)</label>
          <input
            id="expiresInDays"
            type="number"
            min={1}
            max={365}
            value={expiresInDays}
            onChange={(event) => setExpiresInDays(event.target.value)}
          />
        </div>
      </div>
      <div className="row">
        <button type="button" onClick={loadResidents}>
          Bewohner laden
        </button>
        <button
          type="button"
          className="secondary"
          disabled={selected.size === 0 || loading}
          onClick={generateCodes}
        >
          Codes erzeugen (Bulk)
        </button>
      </div>
      {error && <ErrorNotice error={error} />}
      {loading ? (
        <LoadingState />
      ) : (
        <ResidentsTable
          residents={residents}
          selectable
          selectedIds={selected}
          onToggle={toggleResident}
        />
      )}
      {results && (
        <div className="card stack">
          <h3>Ergebnis</h3>
          <div className="row">
            <div className="notice success">
              Erstellt: {results.created.length}
            </div>
            <div className="notice">Übersprungen: {results.skipped.length}</div>
          </div>
          {results.skipped.length > 0 && (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Bewohner</th>
                    <th>Grund</th>
                  </tr>
                </thead>
                <tbody>
                  {results.skipped.map((entry) => (
                    <tr key={`${entry.residentId}-${entry.reason}`}>
                      <td>{entry.residentId}</td>
                      <td>{entry.reason}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <div className="row">
            <button type="button" onClick={exportCsv} disabled={codes.length === 0}>
              Export CSV
            </button>
            <button
              type="button"
              className="secondary"
              onClick={copyCsv}
              disabled={codes.length === 0}
            >
              CSV kopieren
            </button>
            {copyStatus && <span className="small">{copyStatus}</span>}
          </div>
        </div>
      )}
    </div>
  );
}
