'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ErrorNotice from '../../components/ErrorNotice';
import LoadingState from '../../components/LoadingState';
import { ApiError, buildAdminHeaders } from '../../lib/api';
import {
  AdminSession,
  getDefaultSession,
  loadSession,
  saveSession,
} from '../../lib/storage';

export default function LoginPage() {
  const router = useRouter();
  const [session, setSession] = useState<AdminSession>(getDefaultSession());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  useEffect(() => {
    const existing = loadSession();
    if (existing) {
      router.replace('/dashboard');
    }
  }, [router]);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(
        new URL('/api/admin/users', session.apiBaseUrl).toString(),
        {
          method: 'GET',
          headers: buildAdminHeaders(session),
        },
      );
      if (!response.ok) {
        const text = await response.text();
        let message = 'Admin-Berechtigung konnte nicht bestätigt werden.';
        if (text) {
          try {
            const parsed = JSON.parse(text);
            if (parsed && typeof parsed.message === 'string') {
              message = parsed.message;
            } else {
              message = text;
            }
          } catch {
            message = text;
          }
        }
        throw new ApiError(message, response.status, text);
      }

      saveSession(session);
      router.replace('/dashboard');
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err);
      } else {
        setError(
          new ApiError(
            'Backend nicht erreichbar. Bitte API Base URL prüfen.',
            0,
            err,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <LoadingState message="Admin-Zugang wird geprüft..." />;
  }

  return (
    <div className="card stack">
      <div>
        <h2>Admin Login</h2>
        <p className="small">
          Bitte geben Sie die Tenant-Informationen und Ihren Admin-Key an.
        </p>
      </div>
      <ErrorNotice error={error} />
      <form className="stack" onSubmit={onSubmit}>
        <div className="row">
          <div className="field">
            <label htmlFor="tenant">Tenant</label>
            <input
              id="tenant"
              value={session.tenant}
              onChange={(event) =>
                setSession({ ...session, tenant: event.target.value })
              }
              required
            />
          </div>
          <div className="field">
            <label htmlFor="siteKey">Site Key</label>
            <input
              id="siteKey"
              value={session.siteKey}
              onChange={(event) =>
                setSession({ ...session, siteKey: event.target.value })
              }
              required
            />
          </div>
        </div>
        <div className="row">
          <div className="field">
            <label htmlFor="adminKey">Admin Key</label>
            <input
              id="adminKey"
              type="password"
              value={session.adminKey}
              onChange={(event) =>
                setSession({ ...session, adminKey: event.target.value })
              }
              required
            />
          </div>
          <div className="field">
            <label htmlFor="apiBaseUrl">API Base URL</label>
            <input
              id="apiBaseUrl"
              value={session.apiBaseUrl}
              onChange={(event) =>
                setSession({ ...session, apiBaseUrl: event.target.value })
              }
              required
            />
          </div>
        </div>
        <div className="row">
          <button type="submit">Login</button>
        </div>
      </form>
    </div>
  );
}
