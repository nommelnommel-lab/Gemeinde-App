'use client';

import { FormEvent, useState } from 'react';
import ErrorNotice from './ErrorNotice';
import { apiFetch } from '../lib/api';

type ImportSummary = {
  created: number;
  skipped: number;
  failed: number;
  errors: Array<{ row: number; message: string }>;
};

export default function ImportPanel() {
  const [file, setFile] = useState<File | null>(null);
  const [summary, setSummary] = useState<ImportSummary | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!file) {
      return;
    }
    setLoading(true);
    setError(null);
    setSummary(null);

    try {
      const formData = new FormData();
      formData.append('file', file);
      const result = await apiFetch<ImportSummary>(
        '/api/admin/residents/import',
        {
          method: 'POST',
          body: formData,
        },
      );
      setSummary(result);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="stack">
      <div className="card">
        <h2>CSV Import</h2>
        <p className="small">
          CSV-Spalten: firstName,lastName,postalCode,houseNumber (Case-insensitive).
        </p>
        <form className="stack" onSubmit={onSubmit}>
          <input
            type="file"
            accept=".csv"
            onChange={(event) => setFile(event.target.files?.[0] ?? null)}
          />
          <button type="submit" disabled={!file || loading}>
            {loading ? 'Importiere...' : 'Import starten'}
          </button>
        </form>
      </div>
      {error && <ErrorNotice error={error} />}
      {summary && (
        <div className="card stack">
          <h3>Import-Ergebnis</h3>
          <div className="row">
            <div className="notice success">Erstellt: {summary.created}</div>
            <div className="notice">Übersprungen: {summary.skipped}</div>
            <div className="notice error">Fehlgeschlagen: {summary.failed}</div>
          </div>
          {summary.errors.length > 0 && (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Zeile</th>
                    <th>Fehler</th>
                  </tr>
                </thead>
                <tbody>
                  {summary.errors.map((entry) => (
                    <tr key={`${entry.row}-${entry.message}`}>
                      <td>{entry.row}</td>
                      <td>{entry.message}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
