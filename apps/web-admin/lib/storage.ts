export type AdminSession = {
  tenant: string;
  siteKey: string;
  adminKey: string;
  apiBaseUrl: string;
};

const STORAGE_KEY = 'gemeindeAdminSession';

export const getDefaultSession = (): AdminSession => {
  return {
    tenant: process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? '',
    siteKey: process.env.NEXT_PUBLIC_DEFAULT_SITE_KEY ?? '',
    adminKey: '',
    apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000',
  };
};

export const loadSession = (): AdminSession | null => {
  if (typeof window === 'undefined') {
    return null;
  }
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw) as AdminSession;
    if (!parsed?.tenant || !parsed?.siteKey || !parsed?.adminKey) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
};

export const saveSession = (session: AdminSession) => {
  if (typeof window === 'undefined') {
    return;
  }
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
};

export const clearSession = () => {
  if (typeof window === 'undefined') {
    return;
  }
  window.localStorage.removeItem(STORAGE_KEY);
};
