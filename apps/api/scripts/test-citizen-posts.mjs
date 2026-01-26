const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000';
const TENANT = process.env.TENANT ?? 'hilders';
const SITE_KEY = process.env.SITE_KEY ?? process.env.X_SITE_KEY ?? '';
const ADMIN_KEY = process.env.ADMIN_KEY ?? process.env.X_ADMIN_KEY ?? '';

const headersPublic = () => ({
  'X-TENANT': TENANT,
  'X-SITE-KEY': SITE_KEY,
});

const headersAdmin = () => ({
  'X-TENANT': TENANT,
  'X-SITE-KEY': SITE_KEY,
  'X-ADMIN-KEY': ADMIN_KEY,
});

const headersAuth = (token) => ({
  ...headersPublic(),
  Authorization: `Bearer ${token}`,
});

const ensureRequiredEnv = () => {
  const missing = [];
  if (!SITE_KEY) {
    missing.push('SITE_KEY (oder X_SITE_KEY)');
  }
  if (!ADMIN_KEY) {
    missing.push('ADMIN_KEY (oder X_ADMIN_KEY)');
  }
  if (missing.length === 0) {
    return;
  }
  // eslint-disable-next-line no-console
  console.error(
    [
      'Setze die fehlenden ENV Variablen und starte erneut:',
      `Fehlt: ${missing.join(', ')}`,
      '',
      '$env:SITE_KEY="HD-2026-9f3c1a2b-KEY"',
      '$env:ADMIN_KEY="HD-ADMIN-TEST-KEY"',
      '$env:TENANT="hilders"',
      '$env:BASE_URL="http://localhost:3000"',
      '$env:DEBUG="1"',
      'npm --prefix apps/api run test:citizen-posts',
    ].join('\n'),
  );
  process.exit(1);
};

const maskKey = (value) => {
  if (!value) {
    return '<missing>';
  }
  const prefixLength = Math.min(4, value.length);
  const prefix = value.slice(0, prefixLength);
  return `${prefix}***`;
};

const logDebug = (method, path, headers = {}) => {
  if (process.env.DEBUG !== '1') {
    return;
  }
  const tenantSet = Boolean(TENANT);
  const siteKeyValue = headers['X-SITE-KEY'] ?? SITE_KEY;
  const adminKeyValue = headers['X-ADMIN-KEY'];
  const siteKeyLength = siteKeyValue ? siteKeyValue.length : 0;
  const adminKeyLength = adminKeyValue ? adminKeyValue.length : 0;
  const siteKeyMasked = maskKey(siteKeyValue);
  const adminKeyMasked = maskKey(adminKeyValue);
  // eslint-disable-next-line no-console
  console.info(
    `[debug] ${method} ${path} tenant=${tenantSet ? 'yes' : 'no'} ` +
      `siteKey=${siteKeyLength} (${siteKeyMasked}) ` +
      `adminKey=${adminKeyLength} (${adminKeyMasked})`,
  );
};

const parseBody = async (response) => {
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

const requestJson = async (path, { method = 'POST', headers, body }) => {
  logDebug(method, path, headers);
  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await parseBody(response);
  return { response, data };
};

const requireOk = async (path, options) => {
  const { response, data } = await requestJson(path, options);
  if (!response.ok) {
    const status = response.status;
    const body = data ? JSON.stringify(data) : 'EMPTY';
    throw new Error(`Request failed ${status} ${path}: ${body}`);
  }
  return data;
};

const createResident = async (suffix) => {
  const payload = {
    firstName: `Citizen${suffix}`,
    lastName: 'Tester',
    postalCode: '36115',
    houseNumber: '12A',
  };
  const data = await requireOk('/api/admin/residents', {
    headers: headersAdmin(),
    body: payload,
  });
  if (!data?.residentId) {
    throw new Error(`Missing residentId in response: ${JSON.stringify(data)}`);
  }
  return { residentId: data.residentId, ...payload };
};

const issueActivationCode = async (residentId) => {
  const data = await requireOk('/api/admin/activation-codes', {
    headers: headersAdmin(),
    body: { residentId, expiresInDays: 14 },
  });
  if (!data?.code) {
    throw new Error(`Missing code in response: ${JSON.stringify(data)}`);
  }
  return data.code;
};

const activateOnce = async ({
  activationCode,
  email,
  password,
  postalCode,
  houseNumber,
}) =>
  requireOk('/api/auth/activate', {
    headers: headersPublic(),
    body: {
      activationCode,
      email,
      password,
      postalCode,
      houseNumber,
    },
  });

const login = async (email, password) =>
  requireOk('/api/auth/login', {
    headers: headersPublic(),
    body: {
      email,
      password,
    },
  });

const run = async () => {
  ensureRequiredEnv();
  const suffix = Date.now();
  const resident = await createResident(suffix);
  const activationCode = await issueActivationCode(resident.residentId);
  const email = `citizen.${suffix}@example.com`;
  const password = 'secret-pass-123';

  await activateOnce({
    activationCode,
    email,
    password,
    postalCode: resident.postalCode,
    houseNumber: resident.houseNumber,
  });

  const auth = await login(email, password);
  const accessToken = auth?.accessToken;
  if (!accessToken) {
    throw new Error(`Missing accessToken: ${JSON.stringify(auth)}`);
  }

  const created = await requireOk('/posts', {
    headers: headersAuth(accessToken),
    body: {
      type: 'marketplace',
      title: 'Bücherregal aus Holz',
      body: 'Gut erhalten, Abholung möglich.',
      metadata: {
        price: '25',
        location: 'Hilders',
        contact: email,
      },
    },
  });

  if (!created?.id) {
    throw new Error(`Missing post id: ${JSON.stringify(created)}`);
  }

  const list = await requireOk('/posts?type=marketplace', {
    method: 'GET',
    headers: headersPublic(),
  });

  if (!Array.isArray(list) || !list.some((item) => item.id === created.id)) {
    throw new Error('Created post not found in list.');
  }

  await requireOk(`/posts/${created.id}/report`, {
    headers: headersAuth(accessToken),
    body: {},
  });

  // eslint-disable-next-line no-console
  console.info('DONE ✅');
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
