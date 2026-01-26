'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';
import { buildCsv, downloadCsv } from '../lib/csv';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type TouristCodeItem = {
  id: string;
  durationDays: number;
  status: string;
  redeemedAt: string | null;
  createdAt: string;
};

type GenerateResponse = {
  codes: string[];
  durationDays: number;
};

export default function TouristCodesPanel() {
  const [durationDays, setDurationDays] = useState('7');
  const [amount, setAmount] = useState('10');
  const [generated, setGenerated] = useState<string[]>([]);
  const [generatedDuration, setGeneratedDuration] = useState<number | null>(
    null,
  );
  const [items, setItems] = useState<TouristCodeItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [copyStatus, setCopyStatus] = useState<string | null>(null);

  const loadCodes = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiFetch<{ items: TouristCodeItem[] }>(
        '/api/admin/tourist-codes',
      );
      setItems(response.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCodes();
  }, []);

  const handleGenerate = async () => {
    setLoading(true);
    setError(null);
    setCopyStatus(null);
    try {
      const response = await apiFetch<GenerateResponse>(
        '/api/admin/tourist-codes/generate',
        {
          method: 'POST',
          body: JSON.stringify({
            durationDays: Number.parseInt(durationDays, 10),
            amount: Number.parseInt(amount, 10),
          }),
        },
      );
      setGenerated(response.codes ?? []);
      setGeneratedDuration(response.durationDays ?? null);
      await loadCodes();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const handleRevoke = async (id: string) => {
    const confirmed = window.confirm(
      'Möchtest du diesen Tourist-Code wirklich widerrufen?',
    );
    if (!confirmed) {
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/tourist-codes/${id}/revoke`, {
        method: 'POST',
      });
      await loadCodes();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const generatedCsv = useMemo(() => {
    const durationLabel =
      generatedDuration !== null ? String(generatedDuration) : durationDays;
    return buildCsv(
      ['code', 'durationDays'],
      generated.map((code) => [code, durationLabel]),
      ';',
    );
  }, [generated, durationDays, generatedDuration]);

  const copyCode = async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      setCopyStatus('Code kopiert.');
    } catch {
      setCopyStatus('Kopieren fehlgeschlagen.');
    }
  };

  const downloadGeneratedCsv = () => {
    downloadCsv('tourist-codes.csv', generatedCsv);
  };

  return (
    <div className="stack">
      <div className="card">
        <h2>Tourist-Codes generieren</h2>
        <div className="row">
          <div className="field">
            <label htmlFor="durationDays">Dauer (Tage)</label>
            <select
              id="durationDays"
              value={durationDays}
              onChange={(event) => setDurationDays(event.target.value)}
            >
              <option value="7">7 Tage</option>
              <option value="14">14 Tage</option>
              <option value="30">30 Tage</option>
            </select>
          </div>
          <div className="field">
            <label htmlFor="amount">Anzahl</label>
            <input
              id="amount"
              type="number"
              min={1}
              max={1000}
              value={amount}
              onChange={(event) => setAmount(event.target.value)}
            />
          </div>
          <div className="field" style={{ alignSelf: 'flex-end' }}>
            <button type="button" onClick={handleGenerate} disabled={loading}>
              {loading ? 'Bitte warten…' : 'Generieren'}
            </button>
          </div>
        </div>
        {copyStatus && <p className="helper">{copyStatus}</p>}
      </div>

      {error && <ErrorNotice error={error} />}
      {loading && <LoadingState label="Tourist-Codes laden..." />}

      {generated.length > 0 && (
        <div className="card">
          <div className="row" style={{ justifyContent: 'space-between' }}>
            <h3>Neu generierte Codes</h3>
            <div className="row">
              <button
                type="button"
                className="ghost"
                onClick={downloadGeneratedCsv}
              >
                CSV herunterladen
              </button>
            </div>
          </div>
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Dauer</th>
                  <th>Aktion</th>
                </tr>
              </thead>
              <tbody>
                {generated.map((code) => (
                  <tr key={code}>
                    <td>{code}</td>
                    <td>
                      {(generatedDuration ?? Number.parseInt(durationDays, 10))} Tage
                    </td>
                    <td>
                      <button
                        type="button"
                        className="ghost"
                        onClick={() => copyCode(code)}
                      >
                        Kopieren
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <div className="card">
        <h3>Vorhandene Tourist-Codes</h3>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Status</th>
                <th>Dauer</th>
                <th>Eingelöst am</th>
                <th>Erstellt am</th>
                <th>Aktion</th>
              </tr>
            </thead>
            <tbody>
              {items.length === 0 && (
                <tr>
                  <td colSpan={5}>Keine Tourist-Codes vorhanden.</td>
                </tr>
              )}
              {items.map((item) => (
                <tr key={item.id}>
                  <td>{item.status}</td>
                  <td>{item.durationDays} Tage</td>
                  <td>{item.redeemedAt ?? '—'}</td>
                  <td>{item.createdAt}</td>
                  <td>
                    {item.status === 'ACTIVE' ? (
                      <button
                        type="button"
                        className="ghost"
                        onClick={() => handleRevoke(item.id)}
                      >
                        Widerrufen
                      </button>
                    ) : (
                      '—'
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
