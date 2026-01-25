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
  'X-TENANT': TENANT,
  'X-SITE-KEY': SITE_KEY,
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
      'npm --prefix apps/api run test:role-permissions',
    ].join('\n'),
  );
  process.exit(1);
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
    firstName: `Role${suffix}`,
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

const bulkGenerateCode = async (residentId) => {
  const data = await requireOk('/api/admin/activation-codes/bulk', {
    headers: headersAdmin(),
    body: { residentIds: [residentId], expiresInDays: 14 },
  });
  if (!Array.isArray(data?.created) || data.created.length === 0) {
    throw new Error(`Missing created codes: ${JSON.stringify(data)}`);
  }
  return data.created[0].code;
};

const activate = async ({
  activationCode,
  email,
  password,
  postalCode,
  houseNumber,
}) => {
  return requireOk('/api/auth/activate', {
    headers: headersPublic(),
    body: {
      activationCode,
      email,
      password,
      postalCode,
      houseNumber,
    },
  });
};

const createEventPayload = (suffix) => {
  const now = new Date();
  const startAt = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  return {
    title: `Staff Event ${suffix}`,
    description: 'Testevent für Rollen',
    location: 'Rathaus',
    startAt: startAt.toISOString(),
  };
};

const verifyPermissions = async (token) => {
  const permissions = await requireOk('/permissions', {
    method: 'GET',
    headers: headersAuth(token),
  });
  if (permissions?.role !== 'STAFF') {
    throw new Error(
      `Expected role STAFF in /permissions, got ${JSON.stringify(permissions)}`,
    );
  }
  if (permissions?.isAdmin !== false) {
    throw new Error(
      `Expected isAdmin false in /permissions, got ${JSON.stringify(permissions)}`,
    );
  }
};

const run = async () => {
  ensureRequiredEnv();
  const suffix = Date.now();

  const staffResident = await createResident(`Staff${suffix}`);
  const staffCode = await bulkGenerateCode(staffResident.residentId);
  const staffEmail = `staff.${suffix}@example.com`;
  const staffPassword = 'secret-pass-123';
  const staffAuth = await activate({
    activationCode: staffCode,
    email: staffEmail,
    password: staffPassword,
    postalCode: staffResident.postalCode,
    houseNumber: staffResident.houseNumber,
  });

  const userResident = await createResident(`User${suffix}`);
  const userCode = await bulkGenerateCode(userResident.residentId);
  const userEmail = `user.${suffix}@example.com`;
  const userPassword = 'secret-pass-123';
  const userAuth = await activate({
    activationCode: userCode,
    email: userEmail,
    password: userPassword,
    postalCode: userResident.postalCode,
    houseNumber: userResident.houseNumber,
  });

  if (!staffAuth?.user?.id || !staffAuth?.accessToken) {
    throw new Error(`Missing staff auth response: ${JSON.stringify(staffAuth)}`);
  }

  await requireOk('/api/admin/users/role', {
    headers: headersAdmin(),
    body: { userId: staffAuth.user.id, role: 'STAFF' },
  });

  await verifyPermissions(staffAuth.accessToken);

  await requireOk('/api/admin/events', {
    headers: headersAuth(staffAuth.accessToken),
    body: createEventPayload(suffix),
  });

  const { response: userEventResponse, data: userEventData } =
    await requestJson('/api/admin/events', {
      headers: headersAuth(userAuth.accessToken),
      body: createEventPayload(`User${suffix}`),
    });

  if (userEventResponse.status !== 403) {
    const body = userEventData ? JSON.stringify(userEventData) : 'EMPTY';
    throw new Error(
      `Expected 403 for USER create event, got ${userEventResponse.status}: ${body}`,
    );
  }

  // eslint-disable-next-line no-console
  console.info('PASS: Role permissions check ✅');
};

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('FAIL: Role permissions check ❌');
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
