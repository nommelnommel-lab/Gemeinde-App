'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type ModerationPost = {
  id: string;
  tenantId: string;
  type: string;
  title: string;
  body: string;
  status: 'PUBLISHED' | 'HIDDEN';
  reportsCount: number;
  reportedAt?: string;
  hiddenReason?: string;
  createdAt: string;
  updatedAt: string;
};

const typeOptions = [
  { value: '', label: 'Alle Typen' },
  { value: 'USER_POST', label: 'Freier Beitrag' },
  { value: 'MARKETPLACE_LISTING', label: 'Marktplatz' },
  { value: 'HELP_REQUEST', label: 'Hilfegesuch' },
  { value: 'HELP_OFFER', label: 'Hilfeangebot' },
  { value: 'MOVING_CLEARANCE', label: 'Umzug' },
  { value: 'CAFE_MEETUP', label: 'Café-Treffen' },
  { value: 'KIDS_MEETUP', label: 'Kinder-Treffen' },
  { value: 'APARTMENT_SEARCH', label: 'Wohnungssuche' },
  { value: 'LOST_FOUND', label: 'Fundbüro' },
  { value: 'RIDE_SHARING', label: 'Mitfahrgelegenheit' },
  { value: 'JOBS_LOCAL', label: 'Jobs' },
  { value: 'VOLUNTEERING', label: 'Ehrenamt' },
  { value: 'GIVEAWAY', label: 'Verschenken' },
  { value: 'SKILL_EXCHANGE', label: 'Talentbörse' },
];

export default function ModerationPanel() {
  const [typeFilter, setTypeFilter] = useState('');
  const [reportedPosts, setReportedPosts] = useState<ModerationPost[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [detailPost, setDetailPost] = useState<ModerationPost | null>(null);
  const [hideTarget, setHideTarget] = useState<ModerationPost | null>(null);
  const [hideReason, setHideReason] = useState('');

  const loadReported = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (typeFilter) {
        params.set('type', typeFilter);
      }
      const data = await apiFetch<ModerationPost[]>(
        `/api/admin/posts/reported${params.toString() ? `?${params.toString()}` : ''}`,
      );
      setReportedPosts(data ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReported();
  }, [typeFilter]);

  const handleHide = async () => {
    if (!hideTarget) {
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/posts/${hideTarget.id}/hide`, {
        method: 'PATCH',
        body: JSON.stringify({ reason: hideReason.trim() || undefined }),
      });
      setHideTarget(null);
      setHideReason('');
      await loadReported();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const handleUnhide = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/posts/${id}/unhide`, { method: 'PATCH' });
      await loadReported();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const handleResetReports = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/posts/${id}/reset-reports`, { method: 'PATCH' });
      await loadReported();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const sortedPosts = useMemo(
    () =>
      [...reportedPosts].sort(
        (a, b) => (b.reportsCount ?? 0) - (a.reportsCount ?? 0),
      ),
    [reportedPosts],
  );

  return (
    <div className="stack">
      <div className="card stack">
        <div className="row">
          <div className="field">
            <label htmlFor="typeFilter">Typ</label>
            <select
              id="typeFilter"
              value={typeFilter}
              onChange={(event) => setTypeFilter(event.target.value)}
            >
              {typeOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
          <button type="button" onClick={loadReported}>
            Aktualisieren
          </button>
        </div>
        {error && <ErrorNotice error={error} />}
        {loading ? (
          <LoadingState />
        ) : sortedPosts.length === 0 ? (
          <p>Keine gemeldeten Beiträge gefunden.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Titel</th>
                  <th>Typ</th>
                  <th>Reports</th>
                  <th>Status</th>
                  <th>Gemeldet</th>
                  <th>Aktionen</th>
                </tr>
              </thead>
              <tbody>
                {sortedPosts.map((post) => (
                  <tr key={post.id}>
                    <td>{post.title}</td>
                    <td>{post.type}</td>
                    <td>{post.reportsCount}</td>
                    <td>{post.status}</td>
                    <td>
                      {post.reportedAt
                        ? new Date(post.reportedAt).toLocaleString()
                        : '-'}
                    </td>
                    <td className="row">
                      <button
                        type="button"
                        className="secondary"
                        onClick={() => setDetailPost(post)}
                      >
                        Details
                      </button>
                      {post.status === 'HIDDEN' ? (
                        <button
                          type="button"
                          className="secondary"
                          onClick={() => handleUnhide(post.id)}
                        >
                          Einblenden
                        </button>
                      ) : (
                        <button
                          type="button"
                          className="secondary"
                          onClick={() => {
                            setHideTarget(post);
                            setHideReason('');
                          }}
                        >
                          Ausblenden
                        </button>
                      )}
                      <button
                        type="button"
                        className="secondary"
                        onClick={() => handleResetReports(post.id)}
                      >
                        Reports zurücksetzen
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {detailPost && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal stack">
            <h3>Beitrag Details</h3>
            <p>
              <strong>{detailPost.title}</strong>
            </p>
            <p>{detailPost.body}</p>
            <div className="details">
              <div>Typ: {detailPost.type}</div>
              <div>Status: {detailPost.status}</div>
              <div>Reports: {detailPost.reportsCount}</div>
              {detailPost.hiddenReason && (
                <div>Grund: {detailPost.hiddenReason}</div>
              )}
            </div>
            <div className="row">
              <button
                type="button"
                className="secondary"
                onClick={() => setDetailPost(null)}
              >
                Schließen
              </button>
            </div>
          </div>
        </div>
      )}

      {hideTarget && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal stack">
            <h3>Beitrag ausblenden</h3>
            <p>
              Grund für das Ausblenden von <strong>{hideTarget.title}</strong>
            </p>
            <div className="field">
              <label htmlFor="hideReason">Grund (optional)</label>
              <textarea
                id="hideReason"
                rows={3}
                value={hideReason}
                onChange={(event) => setHideReason(event.target.value)}
              />
            </div>
            <div className="row">
              <button type="button" onClick={handleHide}>
                Ausblenden
              </button>
              <button
                type="button"
                className="secondary"
                onClick={() => {
                  setHideTarget(null);
                  setHideReason('');
                }}
              >
                Abbrechen
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
