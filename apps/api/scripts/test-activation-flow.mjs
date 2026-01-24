const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000';
const TENANT = process.env.TENANT ?? 'hilders';
const SITE_KEY = process.env.SITE_KEY ?? 'HD-2026-9f3c1a2b-KEY';
const ADMIN_KEY = process.env.ADMIN_KEY ?? 'ADMIN-KEY-1';

const adminHeaders = () => ({
  'Content-Type': 'application/json',
  'X-TENANT': TENANT,
  'X-SITE-KEY': SITE_KEY,
  'X-ADMIN-KEY': ADMIN_KEY,
});

const siteHeaders = () => ({
  'Content-Type': 'application/json',
  'X-TENANT': TENANT,
  'X-SITE-KEY': SITE_KEY,
});

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
  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
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
    headers: adminHeaders(),
    body: payload,
  });
  if (!data?.residentId) {
    throw new Error(`Missing residentId in response: ${JSON.stringify(data)}`);
  }
  return { residentId: data.residentId, ...payload };
};

const createActivationCode = async (residentId) => {
  const data = await requireOk('/api/admin/activation-codes', {
    headers: adminHeaders(),
    body: { residentId, expiresInDays: 14 },
  });
  if (!data?.code) {
    throw new Error(`Missing code in response: ${JSON.stringify(data)}`);
  }
  return data.code;
};

const activate = async ({ activationCode, email, postalCode, houseNumber }) =>
  requireOk('/api/auth/activate', {
    headers: siteHeaders(),
    body: {
      activationCode,
      email,
      password: 'secret-pass-123',
      postalCode,
      houseNumber,
    },
  });

const login = async (email) =>
  requireOk('/api/auth/login', {
    headers: siteHeaders(),
    body: {
      email,
      password: 'secret-pass-123',
    },
  });

const refresh = async (refreshToken) =>
  requireOk('/api/auth/refresh', {
    headers: siteHeaders(),
    body: { refreshToken },
  });

const logout = async (refreshToken) =>
  requireOk('/api/auth/logout', {
    headers: siteHeaders(),
    body: { refreshToken },
  });

const run = async () => {
  const residentExact = await createResident('Exact');
  const codeExact = await createActivationCode(residentExact.residentId);
  if (!codeExact.includes('-')) {
    throw new Error(`Expected activation code to include dashes: ${codeExact}`);
  }

  const exactEmail = 'activation.tester.exact@example.com';
  await activate({
    activationCode: codeExact,
    email: exactEmail,
    postalCode: residentExact.postalCode,
    houseNumber: residentExact.houseNumber,
  });

  await expectStatus(
    '/api/auth/activate',
    {
      headers: siteHeaders(),
      body: {
        activationCode: codeExact,
        email: 'activation.tester.exact.retry@example.com',
        password: 'secret-pass-123',
        postalCode: residentExact.postalCode,
        houseNumber: residentExact.houseNumber,
      },
    },
    401,
  );

  const residentNormalized = await createResident('Normalized');
  const normalizedCode = await createActivationCode(
    residentNormalized.residentId,
  );
  await activate({
    activationCode: normalizedCode.replace(/[-\s]/g, ''),
    email: 'activation.tester.normalized@example.com',
    postalCode: residentNormalized.postalCode,
    houseNumber: residentNormalized.houseNumber,
  });

  const residentTrimmed = await createResident('Trimmed');
  const trimmedCode = await createActivationCode(residentTrimmed.residentId);
  await activate({
    activationCode: `  ${trimmedCode}  `,
    email: 'activation.tester.trimmed@example.com',
    postalCode: residentTrimmed.postalCode,
    houseNumber: residentTrimmed.houseNumber,
  });

  const loginResponse = await login(exactEmail);
  if (!loginResponse?.refreshToken) {
    throw new Error(`Missing refreshToken on login: ${JSON.stringify(loginResponse)}`);
  }

  const refreshed = await refresh(loginResponse.refreshToken);
  if (!refreshed?.refreshToken) {
    throw new Error(`Missing refreshToken on refresh: ${JSON.stringify(refreshed)}`);
  }

  await expectStatus(
    '/api/auth/refresh',
    {
      headers: siteHeaders(),
      body: { refreshToken: loginResponse.refreshToken },
    },
    401,
  );

  await logout(refreshed.refreshToken);

  await expectStatus(
    '/api/auth/refresh',
    {
      headers: siteHeaders(),
      body: { refreshToken: refreshed.refreshToken },
    },
    401,
  );

  // eslint-disable-next-line no-console
  console.info('DONE ✅');
};

run().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  // eslint-disable-next-line no-console
  console.error('FAIL', message);
  process.exitCode = 1;
});
