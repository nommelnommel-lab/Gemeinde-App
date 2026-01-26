'use client';

import { useEffect, useMemo, useState } from 'react';
import { ApiError, apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type ModerationPost = {
  id: string;
  tenantId: string;
  type: string;
  title: string;
  body: string;
  authorUserId?: string;
  residentId?: string;
  metadata?: Record<string, unknown>;
  status: 'PUBLISHED' | 'HIDDEN';
  reportsCount: number;
  reportedAt?: string;
  hiddenAt?: string;
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
  const [statusFilter, setStatusFilter] = useState('');
  const [reportedOnly, setReportedOnly] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [reportedPosts, setReportedPosts] = useState<ModerationPost[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [detailPost, setDetailPost] = useState<ModerationPost | null>(null);
  const [hideTarget, setHideTarget] = useState<ModerationPost | null>(null);
  const [hideReason, setHideReason] = useState('');
  const [message, setMessage] = useState('');
  const [connectionError, setConnectionError] = useState(false);
  const [apiStatus, setApiStatus] = useState<'checking' | 'ok' | 'down'>(
    'checking',
  );

  const loadReported = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (typeFilter) {
        params.set('type', typeFilter);
      }
      if (statusFilter) {
        params.set('status', statusFilter);
      }
      params.set('reportedOnly', reportedOnly ? 'true' : 'false');
      if (searchTerm.trim()) {
        params.set('query', searchTerm.trim());
      }
      const data = await apiFetch<ModerationPost[]>(
        `/api/admin/posts/reported${params.toString() ? `?${params.toString()}` : ''}`,
      );
      setReportedPosts(data ?? []);
      setConnectionError(false);
      setApiStatus('ok');
    } catch (err) {
      setError(err);
      if (err instanceof ApiError && err.status === 0) {
        setConnectionError(true);
        setApiStatus('down');
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReported();
  }, [typeFilter, statusFilter, reportedOnly, searchTerm]);

  const checkHealth = async () => {
    setApiStatus('checking');
    try {
      await apiFetch('/health');
      setApiStatus('ok');
    } catch (err) {
      if (err instanceof ApiError && err.status === 0) {
        setApiStatus('down');
        setConnectionError(true);
        return;
      }
      setApiStatus('down');
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  const handleHide = async () => {
    if (!hideTarget) {
      return;
    }
    if (!hideReason.trim()) {
      setError(new Error('Bitte einen Grund für das Ausblenden angeben.'));
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
      setMessage('Beitrag ausgeblendet.');
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
      setMessage('Beitrag eingeblendet.');
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

  const filteredPosts = useMemo(() => {
    const normalizedQuery = searchTerm.trim().toLowerCase();
    if (!normalizedQuery) {
      return sortedPosts;
    }
    return sortedPosts.filter((post) =>
      post.title.toLowerCase().includes(normalizedQuery),
    );
  }, [sortedPosts, searchTerm]);

  const resolveAuthor = (post: ModerationPost) => {
    if (post.residentId) {
      return post.residentId;
    }
    if (post.authorUserId) {
      return post.authorUserId;
    }
    const metadataResident =
      post.metadata && typeof post.metadata === 'object'
        ? (post.metadata as { residentId?: string }).residentId
        : undefined;
    return metadataResident ?? '-';
  };

  const handleRetry = async () => {
    await checkHealth();
    await loadReported();
  };

  useEffect(() => {
    if (!message) {
      return undefined;
    }
    const timeout = window.setTimeout(() => setMessage(''), 4000);
    return () => window.clearTimeout(timeout);
  }, [message]);

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
          <div className="field">
            <label htmlFor="statusFilter">Status</label>
            <select
              id="statusFilter"
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              <option value="">Alle Status</option>
              <option value="PUBLISHED">PUBLISHED</option>
              <option value="HIDDEN">HIDDEN</option>
            </select>
          </div>
          <div className="field">
            <label htmlFor="reportedOnly">Nur gemeldet</label>
            <input
              id="reportedOnly"
              type="checkbox"
              checked={reportedOnly}
              onChange={(event) => setReportedOnly(event.target.checked)}
            />
          </div>
          <div className="field">
            <label htmlFor="searchTerm">Titel enthält</label>
            <input
              id="searchTerm"
              type="search"
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
            />
          </div>
          <div className="field">
            <label>&nbsp;</label>
            <button type="button" onClick={loadReported}>
              Aktualisieren
            </button>
          </div>
          <div className="field">
            <label>API</label>
            <span
              className={`badge health-pill ${apiStatus === 'ok' ? 'success' : apiStatus === 'down' ? 'error' : ''}`}
            >
              {apiStatus === 'checking'
                ? 'prüfe...'
                : apiStatus === 'ok'
                  ? 'ok'
                  : 'down'}
            </span>
          </div>
        </div>
        {connectionError && (
          <div className="notice error">
            Backend nicht erreichbar.{' '}
            <button type="button" onClick={handleRetry}>
              Erneut versuchen
            </button>
          </div>
        )}
        {message && <div className="notice success">{message}</div>}
        {error && !connectionError && <ErrorNotice error={error} />}
        {loading ? (
          <LoadingState />
        ) : filteredPosts.length === 0 ? (
          <p>Keine gemeldeten Beiträge gefunden.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Erstellt</th>
                  <th>Typ</th>
                  <th>Titel</th>
                  <th>Autor</th>
                  <th>Reports</th>
                  <th>Status</th>
                  <th>Aktionen</th>
                </tr>
              </thead>
              <tbody>
                {filteredPosts.map((post) => (
                  <tr key={post.id}>
                    <td>{new Date(post.createdAt).toLocaleString()}</td>
                    <td>{post.type}</td>
                    <td>{post.title}</td>
                    <td>{resolveAuthor(post)}</td>
                    <td>{post.reportsCount}</td>
                    <td>{post.status}</td>
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
              <div>Erstellt: {new Date(detailPost.createdAt).toLocaleString()}</div>
              <div>Status: {detailPost.status}</div>
              <div>Reports: {detailPost.reportsCount}</div>
              <div>
                Gemeldet:{' '}
                {detailPost.reportedAt
                  ? new Date(detailPost.reportedAt).toLocaleString()
                  : '-'}
              </div>
              {detailPost.hiddenReason && (
                <div>Grund: {detailPost.hiddenReason}</div>
              )}
              {detailPost.metadata && (
                <div>
                  Metadaten:
                  <pre>{JSON.stringify(detailPost.metadata, null, 2)}</pre>
                </div>
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
              <label htmlFor="hideReason">Grund (erforderlich)</label>
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
