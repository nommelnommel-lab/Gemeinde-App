import { loadSession } from './storage';

export class ApiError extends Error {
  status: number;
  details: unknown;

  constructor(message: string, status: number, details: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

const shouldIncludeAdminKey = (path: string) => {
  return path.startsWith('/api/admin/');
};

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

export const apiFetch = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const session = loadSession();
  if (!session) {
    throw new ApiError('Keine Admin-Sitzung gefunden.', 401, null);
  }

  const headers = new Headers(options.headers ?? {});
  headers.set('X-TENANT', session.tenant);
  headers.set('X-SITE-KEY', session.siteKey);
  if (shouldIncludeAdminKey(path)) {
    headers.set('X-ADMIN-KEY', session.adminKey);
  }

  const body = options.body;
  if (body && !(body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

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
      data && typeof data === 'object' && 'message' in data
        ? String((data as { message: string }).message)
        : 'Anfrage fehlgeschlagen.';
    throw new ApiError(message, response.status, data);
  }

  return data as T;
};
