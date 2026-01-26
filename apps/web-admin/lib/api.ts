import { AdminSession, loadSession } from './storage';

export class ApiError extends Error {
  status: number;
  details: unknown;

  constructor(message: string, status: number, details: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

const buildUrl = (baseUrl: string, path: string) => {
  const normalizedBase = baseUrl.endsWith('/')
    ? baseUrl.slice(0, -1)
    : baseUrl;
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${normalizedBase}${normalizedPath}`;
};

const parseResponseBody = async (response: Response) => {
  const text = await response.text();
  if (!text) {
    return null;
  }
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
};

type HeaderOptions = {
  includeJson?: boolean;
  headers?: HeadersInit;
};

export const buildAdminHeaders = (
  session: AdminSession,
  options: HeaderOptions = {},
) => {
  const headers = new Headers(options.headers ?? {});
  headers.set('X-TENANT', session.tenant);
  headers.set('X-SITE-KEY', session.siteKey);
  headers.set('X-ADMIN-KEY', session.adminKey);
  if (options.includeJson && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }
  return headers;
};

export const apiFetch = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const session = loadSession();
  if (!session) {
    throw new ApiError('Keine Admin-Sitzung gefunden.', 401, null);
  }

  const body = options.body;
  const headers = buildAdminHeaders(session, {
    headers: options.headers,
    includeJson: Boolean(body && !(body instanceof FormData)),
  });

  let response: Response;
  try {
    response = await fetch(buildUrl(session.apiBaseUrl, path), {
      ...options,
      headers,
    });
  } catch (error) {
    throw new ApiError(
      'Backend nicht erreichbar. Bitte API Base URL prüfen.',
      0,
      error,
    );
  }
  const data = await parseResponseBody(response);

  if (!response.ok) {
    const message =
      response.status === 401 || response.status === 403
        ? 'Sitzung abgelaufen oder keine Berechtigung. Bitte erneut anmelden.'
        : data && typeof data === 'object' && 'message' in data
          ? String((data as { message: string }).message)
          : 'Anfrage fehlgeschlagen.';
    throw new ApiError(message, response.status, data);
  }

  return data as T;
};
