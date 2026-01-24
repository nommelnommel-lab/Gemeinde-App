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
      'npm --prefix apps/api run test:activation-flow',
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

const expectStatus = async (path, options, expectedStatus) => {
  const { response, data } = await requestJson(path, options);
  if (response.status !== expectedStatus) {
    const body = data ? JSON.stringify(data) : 'EMPTY';
    throw new Error(
      `Expected ${expectedStatus} for ${path}, got ${response.status}: ${body}`,
    );
  }
  return data;
};

const createResident = async (suffix) => {
  const payload = {
    firstName: `Activation${suffix}`,
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

const refreshRotate = async (refreshToken) =>
  requireOk('/api/auth/refresh', {
    headers: headersPublic(),
    body: { refreshToken },
  });

const expectRefresh401 = async (refreshToken) =>
  expectStatus(
    '/api/auth/refresh',
    {
      headers: headersPublic(),
      body: { refreshToken },
    },
    401,
  );

const logout = async (refreshToken) =>
  requireOk('/api/auth/logout', {
    headers: headersPublic(),
    body: { refreshToken },
  });

const run = async () => {
  ensureRequiredEnv();
  const resident = await createResident('Flow');
  const activationCode = await issueActivationCode(resident.residentId);
  if (!activationCode.includes('-')) {
    throw new Error(
      `Expected activation code to include dashes: ${activationCode}`,
    );
  }

  const email = 'activation.tester.flow@example.com';
  const password = 'secret-pass-123';
  await activateOnce({
    activationCode,
    email,
    password,
    postalCode: resident.postalCode,
    houseNumber: resident.houseNumber,
  });

  const { response: secondActivateResponse } = await requestJson(
    '/api/auth/activate',
    {
      headers: headersPublic(),
      body: {
        activationCode,
        email: 'activation.tester.flow.retry@example.com',
        password,
        postalCode: resident.postalCode,
        houseNumber: resident.houseNumber,
      },
    },
  );
  if (![401, 409].includes(secondActivateResponse.status)) {
    throw new Error(
      `Unexpected status on second activate attempt: ${secondActivateResponse.status}`,
    );
  }
  // eslint-disable-next-line no-console
  console.info(
    `Second activate attempt: OK expected ${secondActivateResponse.status}`,
  );

  const loginResponse = await login(email, password);
  if (!loginResponse?.refreshToken) {
    throw new Error(`Missing refreshToken on login: ${JSON.stringify(loginResponse)}`);
  }

  const refreshed = await refreshRotate(loginResponse.refreshToken);
  if (!refreshed?.refreshToken) {
    throw new Error(`Missing refreshToken on refresh: ${JSON.stringify(refreshed)}`);
  }

  await expectRefresh401(loginResponse.refreshToken);

  await logout(refreshed.refreshToken);

  await expectRefresh401(refreshed.refreshToken);

  // eslint-disable-next-line no-console
  console.info('DONE ✅');
};

run().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  // eslint-disable-next-line no-console
  console.error('FAIL', message);
  process.exitCode = 1;
});
