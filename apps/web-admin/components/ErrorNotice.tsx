'use client';

import { ApiError } from '../lib/api';

type ErrorNoticeProps = {
  error: unknown;
  title?: string;
};

export default function ErrorNotice({ error, title }: ErrorNoticeProps) {
  if (!error) {
    return null;
  }

  const resolvedTitle = title ?? 'Es ist ein Fehler aufgetreten.';
  const message = error instanceof Error ? error.message : 'Unbekannter Fehler.';
  const details = error instanceof ApiError ? error.details : null;
  const status = error instanceof ApiError ? error.status : null;
  const shouldRelogin = status === 401 || status === 403;
  const messageWithStatus =
    status !== null ? `HTTP ${status}: ${message}` : message;

  return (
    <div className="notice error">
      <strong>{resolvedTitle}</strong>
      <div>{messageWithStatus}</div>
      {shouldRelogin && (
        <div className="row" style={{ marginTop: '0.5rem' }}>
          <button
            type="button"
            onClick={() => {
              if (typeof window !== 'undefined') {
                window.location.href = '/login';
              }
            }}
          >
            Zur Anmeldung
          </button>
        </div>
      )}
      {(details || status) && (
        <details className="details">
          <summary>Debug-Details</summary>
          <pre>
            {JSON.stringify({ status, details }, null, 2)}
          </pre>
        </details>
      )}
    </div>
  );
}
