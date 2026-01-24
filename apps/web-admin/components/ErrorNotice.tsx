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

  return (
    <div className="notice error">
      <strong>{resolvedTitle}</strong>
      <div>{message}</div>
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
