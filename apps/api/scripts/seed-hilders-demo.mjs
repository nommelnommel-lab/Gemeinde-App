const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000';
const SITE_KEY = process.env.SITE_KEY ?? process.env.X_SITE_KEY ?? '';
const ADMIN_KEY = process.env.ADMIN_KEY ?? process.env.X_ADMIN_KEY ?? '';
const TENANT = 'hilders-demo';

const DEMO_PREFIX = 'DEMO:';

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
      '$env:BASE_URL="http://localhost:3000"',
      'npm --prefix apps/api run seed:hilders-demo',
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

const requestJson = async (path, { method = 'POST', headers, body } = {}) => {
  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(headers ?? {}),
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

const safeRequest = async (path, options) => {
  const { response, data } = await requestJson(path, options);
  if (!response.ok) {
    return { ok: false, status: response.status, data };
  }
  return { ok: true, data };
};

const addDays = (base, days, hour = 9) => {
  const date = new Date(base.getTime());
  date.setDate(date.getDate() + days);
  date.setHours(hour, 0, 0, 0);
  return date.toISOString();
};

const ensureStaffToken = async () => {
  const demoEmail = 'demo.admin@hilders.app';
  const demoPassword = 'Demo-Admin-2024!';
  const residentPayload = {
    firstName: 'Demo',
    lastName: 'Admin',
    postalCode: '36115',
    houseNumber: '1',
  };

  const resident = await requireOk('/api/admin/residents', {
    headers: headersAdmin(),
    body: residentPayload,
  });

  const login = async () =>
    requireOk('/api/auth/login', {
      headers: headersPublic(),
      body: {
        email: demoEmail,
        password: demoPassword,
      },
    });

  let auth = await safeRequest('/api/auth/login', {
    headers: headersPublic(),
    body: {
      email: demoEmail,
      password: demoPassword,
    },
  });

  if (!auth.ok) {
    const activation = await requireOk('/api/admin/activation-codes', {
      headers: headersAdmin(),
      body: { residentId: resident.residentId, expiresInDays: 14 },
    });

    await requireOk('/api/auth/activate', {
      headers: headersPublic(),
      body: {
        activationCode: activation.code,
        email: demoEmail,
        password: demoPassword,
        postalCode: residentPayload.postalCode,
        houseNumber: residentPayload.houseNumber,
      },
    });

    auth = await safeRequest('/api/auth/login', {
      headers: headersPublic(),
      body: {
        email: demoEmail,
        password: demoPassword,
      },
    });
  }

  if (!auth.ok || !auth.data?.accessToken) {
    throw new Error(`Login fehlgeschlagen: ${JSON.stringify(auth.data)}`);
  }

  await requireOk('/api/admin/users/role', {
    headers: headersAdmin(),
    body: {
      email: demoEmail,
      role: 'STAFF',
    },
  });

  const refreshed = await login();
  if (!refreshed?.accessToken) {
    throw new Error('Missing accessToken after role update');
  }

  return refreshed.accessToken;
};

const upsertProfile = async () =>
  requireOk('/api/admin/municipality/profile', {
    headers: headersAdmin(),
    body: {
      name: 'Rathaus Infos Hilders',
      address: {
        street: 'Kirchstraße 2-6',
        zip: '36115',
        city: 'Hilders',
      },
      phone: '06681 9608-0',
      fax: '06681 9608-22',
      email: 'rathaus@hilders-demo.de',
      websiteUrl: 'https://www.hilders.de',
      openingHours: [
        {
          weekday: 'Mo',
          slots: [
            { from: '08:30', to: '12:00' },
            { from: '14:00', to: '16:30' },
          ],
        },
        {
          weekday: 'Di',
          slots: [
            { from: '08:30', to: '12:00' },
            { from: '14:00', to: '16:30' },
          ],
        },
        {
          weekday: 'Mi',
          slots: [{ from: '08:30', to: '12:00' }],
        },
        {
          weekday: 'Do',
          slots: [
            { from: '08:30', to: '12:00' },
            { from: '14:00', to: '18:00' },
          ],
        },
        {
          weekday: 'Fr',
          slots: [{ from: '08:30', to: '12:00' }],
        },
      ],
      emergencyNumbers: [
        { label: 'Polizei', number: '110' },
        { label: 'Feuerwehr / Rettungsdienst', number: '112' },
        { label: 'Ärztlicher Bereitschaftsdienst', number: '116117' },
        { label: 'Giftnotruf', number: '0361 730730' },
      ],
      importantLinks: [
        { label: 'Online-Rathaus', url: 'https://www.hilders.de/rathaus' },
        {
          label: 'Formulare & Bürgerservice',
          url: 'https://www.hilders.de/online-rathaus',
        },
        {
          label: 'Amtliche Bekanntmachungen',
          url: 'https://www.hilders.de/rathaus/bekanntmachungen',
        },
        {
          label: 'Veranstaltungskalender',
          url: 'https://www.hilders.de/veranstaltungen',
        },
        { label: 'Abfallkalender', url: 'https://www.hilders.de/abfall' },
      ],
    },
  });

const deleteDemoPosts = async (token, types) => {
  for (const type of types) {
    const posts = await requireOk(
      `/posts?type=${encodeURIComponent(type)}&limit=50`,
      { headers: headersAuth(token), method: 'GET' },
    );
    const demoPosts = posts.filter((post) => post.title?.startsWith(DEMO_PREFIX));
    for (const post of demoPosts) {
      await requireOk(`/posts/${post.id}`, {
        headers: headersAuth(token),
        method: 'DELETE',
      });
    }
  }
};

const createPosts = async (token, posts) => {
  for (const post of posts) {
    await requireOk('/posts', {
      headers: headersAuth(token),
      body: post,
    });
  }
};

const deleteDemoTourism = async (types) => {
  for (const type of types) {
    const items = await requireOk(
      `/api/admin/tourism?type=${encodeURIComponent(type)}`,
      { headers: headersAdmin(), method: 'GET' },
    );
    const demoItems = items.filter((item) => item.title?.startsWith(DEMO_PREFIX));
    for (const item of demoItems) {
      await requireOk(`/api/admin/tourism/${item.id}`, {
        headers: headersAdmin(),
        method: 'DELETE',
      });
    }
  }
};

const createTourism = async (items) => {
  for (const item of items) {
    await requireOk('/api/admin/tourism', {
      headers: headersAdmin(),
      body: item,
    });
  }
};

const seedVerwaltungItems = async (items) => {
  const existing = await requireOk('/api/admin/verwaltung/items', {
    headers: headersAdmin(),
    method: 'GET',
  });
  const existingItems = Array.isArray(existing) ? existing : [];
  const existingByKey = new Map(
    existingItems.map((item) => [`${item.kind}:${item.title}`, item]),
  );
  const incomingKeys = new Set(
    items.map((item) => `${item.kind}:${item.title}`),
  );

  const toHide = existingItems.filter(
    (item) =>
      item.metadata?.demoSeed && !incomingKeys.has(`${item.kind}:${item.title}`),
  );
  for (const item of toHide) {
    await requireOk(`/api/admin/verwaltung/items/${item.id}`, {
      headers: headersAdmin(),
      method: 'DELETE',
    });
  }

  for (const item of items) {
    const payload = {
      ...item,
      metadata: {
        ...(item.metadata ?? {}),
        demoSeed: true,
      },
    };
    const existingItem = existingByKey.get(`${item.kind}:${item.title}`);
    if (existingItem) {
      await requireOk(`/api/admin/verwaltung/items/${existingItem.id}`, {
        headers: headersAdmin(),
        method: 'PATCH',
        body: payload,
      });
    } else {
      await requireOk('/api/admin/verwaltung/items', {
        headers: headersAdmin(),
        body: payload,
      });
    }
  }
};

const seedTouristCodes = async () => {
  const existing = await requireOk(
    '/api/admin/tourist-codes?status=ACTIVE&durationDays=30',
    { headers: headersAdmin(), method: 'GET' },
  );
  for (const code of existing.items ?? []) {
    await requireOk(`/api/admin/tourist-codes/${code.id}/revoke`, {
      headers: headersAdmin(),
      method: 'POST',
    });
  }

  const created = await requireOk('/api/admin/tourist-codes/generate', {
    headers: headersAdmin(),
    body: { durationDays: 30, amount: 2 },
  });

  const codes = created.codes ?? [];
  // eslint-disable-next-line no-console
  console.log(`Tourist codes: ${codes.join(', ')}`);
};

const seed = async () => {
  ensureRequiredEnv();
  const staffToken = await ensureStaffToken();
  await upsertProfile();

  const now = new Date();
  const officialEvents = Array.from({ length: 10 }).map((_, index) => {
    const dateTime = addDays(now, index * 3, 18);
    return {
      type: 'OFFICIAL_EVENT',
      title: `${DEMO_PREFIX} Dorfabend ${index + 1}`,
      body:
        'Gemeinsamer Abend mit Musik, Austausch und regionalen Spezialitäten. Eintritt frei.',
      date: dateTime,
      location: 'Bürgerhaus Hilders',
      metadata: {
        dateTime,
        location: 'Bürgerhaus Hilders',
      },
      status: 'PUBLISHED',
    };
  });

  const officialNews = Array.from({ length: 8 }).map((_, index) => ({
    type: 'OFFICIAL_NEWS',
    title: `${DEMO_PREFIX} Rathaus-Update ${index + 1}`,
    body:
      'Aktuelle Informationen aus dem Rathaus, inkl. Servicezeiten und neuen Angeboten.',
    metadata: {
      source: 'Rathaus Hilders',
      category: 'Verwaltung',
    },
    status: 'PUBLISHED',
  }));

  const warningLevels = ['low', 'medium', 'high'];
  const officialWarnings = Array.from({ length: 5 }).map((_, index) => {
    const severity = warningLevels[index % warningLevels.length];
    const validUntil = addDays(now, index + 3, 20);
    return {
      type: 'OFFICIAL_WARNING',
      title: `${DEMO_PREFIX} Hinweis ${index + 1}: Wetterlage`,
      body:
        'Bitte beachten Sie die aktuellen Hinweise der Gemeinde. Aktualisierte Infos folgen.',
      severity,
      validUntil,
      metadata: {
        severity,
        updatedAt: new Date().toISOString(),
      },
      status: 'PUBLISHED',
    };
  });

  const verwaltungBaseUrl =
    'https://www.hilders.de/rathaus/buergerservice/online-rathaus/formulare-vordrucke-alle';
  const verwaltungLinks = [
    {
      kind: 'LINK',
      category: 'Rathaus/Service',
      title: 'Rathaus Hilders',
      description: 'Zentrale Informationen zu Rathaus, Ämtern und Kontakt.',
      url: 'https://www.hilders.de/rathaus',
      tags: ['rathaus', 'service', 'kontakt'],
      sortOrder: 10,
    },
    {
      kind: 'LINK',
      category: 'Rathaus/Service',
      title: 'Bürgerservice',
      description: 'Anlaufstelle für Anträge, Termine und Bescheinigungen.',
      url: 'https://www.hilders.de/rathaus/buergerservice',
      tags: ['bürgerservice', 'termin', 'auskunft'],
      sortOrder: 11,
    },
    {
      kind: 'LINK',
      category: 'Abfall & Wertstoff',
      title: 'Abfallkalender & Entsorgung',
      description: 'Leerungstermine, Trennhinweise und Entsorgungspunkte.',
      url: 'https://www.hilders.de/abfall',
      tags: ['abfall', 'wertstoff', 'kalender'],
      sortOrder: 20,
    },
    {
      kind: 'LINK',
      category: 'Abfall & Wertstoff',
      title: 'Wertstoffhof Rhönblick',
      description: 'Öffnungszeiten und Annahmebedingungen für Wertstoffe.',
      url: 'https://www.hilders.de/abfall/wertstoffhof',
      tags: ['wertstoffhof', 'recycling'],
      sortOrder: 21,
    },
    {
      kind: 'LINK',
      category: 'Standesamt',
      title: 'Standesamt Hilders',
      description: 'Informationen zu Trauungen, Geburten und Urkunden.',
      url: 'https://www.hilders.de/rathaus/standesamt',
      tags: ['standesamt', 'urkunden', 'trauung'],
      sortOrder: 30,
    },
    {
      kind: 'LINK',
      category: 'Bürgerbüro / Meldewesen',
      title: 'Bürgerbüro',
      description: 'Meldeangelegenheiten, Ausweise und Bescheinigungen.',
      url: 'https://www.hilders.de/rathaus/buergerservice/buergerbuero',
      tags: ['bürgerbüro', 'ausweis', 'meldung'],
      sortOrder: 40,
    },
    {
      kind: 'LINK',
      category: 'Bürgerbüro / Meldewesen',
      title: 'Meldewesen',
      description: 'Ummeldung, Wohnsitzbestätigung und Melderegister.',
      url: 'https://www.hilders.de/rathaus/buergerservice/meldewesen',
      tags: ['meldung', 'wohnort', 'melderegister'],
      sortOrder: 41,
    },
    {
      kind: 'LINK',
      category: 'Kind & Familie',
      title: 'Kinderbetreuung',
      description: 'Kitas, Tagespflege und Betreuungsangebote.',
      url: 'https://www.hilders.de/leben/kinderbetreuung',
      tags: ['kita', 'familie', 'betreuung'],
      sortOrder: 50,
    },
    {
      kind: 'LINK',
      category: 'Kind & Familie',
      title: 'Familienangebote',
      description: 'Ferienprogramme, Beratung und Familienservice.',
      url: 'https://www.hilders.de/leben/familie',
      tags: ['familie', 'beratung', 'ferien'],
      sortOrder: 51,
    },
    {
      kind: 'LINK',
      category: 'Bauen & Wohnen',
      title: 'Bauen & Wohnen',
      description: 'Bauleitplanung, Grundstücke und Bauanträge.',
      url: 'https://www.hilders.de/bauen-wohnen',
      tags: ['bauen', 'wohnen', 'bauantrag'],
      sortOrder: 60,
    },
    {
      kind: 'LINK',
      category: 'Bauen & Wohnen',
      title: 'Bauleitplanung',
      description: 'Aktuelle Planungen, Satzungen und Verfahren.',
      url: 'https://www.hilders.de/bauen-wohnen/bauleitplanung',
      tags: ['bauleitplanung', 'satzung'],
      sortOrder: 61,
    },
    {
      kind: 'LINK',
      category: 'Verkehr',
      title: 'Verkehr & Mobilität',
      description: 'Straßensperrungen, Busverbindungen und Parken.',
      url: 'https://www.hilders.de/verkehr',
      tags: ['verkehr', 'mobilität', 'parken'],
      sortOrder: 70,
    },
    {
      kind: 'LINK',
      category: 'Verkehr',
      title: 'ÖPNV & Rufbus',
      description: 'Fahrpläne, Anschlüsse und Rufbus-Infos.',
      url: 'https://www.hilders.de/verkehr/oepnv',
      tags: ['bus', 'fahrplan', 'rufbus'],
      sortOrder: 71,
    },
    {
      kind: 'LINK',
      category: 'Notfallnummern / Ärzte',
      title: 'Notfallnummern',
      description: 'Wichtige Rufnummern für Notfälle und Bereitschaft.',
      url: 'https://www.hilders.de/notfall',
      tags: ['notfall', 'rettung', 'polizei'],
      sortOrder: 80,
    },
    {
      kind: 'LINK',
      category: 'Notfallnummern / Ärzte',
      title: 'Ärztlicher Bereitschaftsdienst',
      description: 'Kontakt und Erreichbarkeit für ärztliche Hilfe.',
      url: 'https://www.hilders.de/gesundheit/aerzte',
      tags: ['arzt', 'bereitschaft', 'gesundheit'],
      sortOrder: 81,
    },
    {
      kind: 'LINK',
      category: 'Vereinsleben',
      title: 'Vereine in Hilders',
      description: 'Sport, Kultur und Ehrenamt in der Gemeinde.',
      url: 'https://www.hilders.de/leben/vereine',
      tags: ['vereine', 'ehrenamt', 'sport'],
      sortOrder: 90,
    },
    {
      kind: 'LINK',
      category: 'Vereinsleben',
      title: 'Ehrenamt & Engagement',
      description: 'Mitmachen, helfen und Projekte unterstützen.',
      url: 'https://www.hilders.de/leben/ehrenamt',
      tags: ['engagement', 'ehrenamt'],
      sortOrder: 91,
    },
    {
      kind: 'LINK',
      category: 'Tourismus (Wandern, Sehenswürdigkeiten)',
      title: 'Tourismus Hilders',
      description: 'Gastgeber, Freizeitangebote und Ausflugsziele.',
      url: 'https://www.hilders.de/tourismus',
      tags: ['tourismus', 'freizeit', 'ausflüge'],
      sortOrder: 100,
    },
    {
      kind: 'LINK',
      category: 'Tourismus (Wandern, Sehenswürdigkeiten)',
      title: 'Wandern in der Rhön',
      description: 'Tourenvorschläge, Karten und Aussichtspunkte.',
      url: 'https://www.hilders.de/tourismus/wandern',
      tags: ['wandern', 'rhön', 'touren'],
      sortOrder: 101,
    },
    {
      kind: 'LINK',
      category: 'Tourismus (Wandern, Sehenswürdigkeiten)',
      title: 'Sehenswürdigkeiten',
      description: 'Museen, Naturdenkmäler und Aussichtspunkte.',
      url: 'https://www.hilders.de/tourismus/sehenswuerdigkeiten',
      tags: ['sehenswürdigkeiten', 'ausflug', 'kultur'],
      sortOrder: 102,
    },
  ];
  const verwaltungForms = [
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Wohnsitz anmelden',
      description: 'Anmeldung einer neuen Wohnung innerhalb der Gemeinde.',
      url: verwaltungBaseUrl,
      tags: ['wohnungsanmeldung', 'umzug', 'meldung'],
      sortOrder: 200,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Wohnsitz ummelden',
      description: 'Ummeldung bei Umzug innerhalb Hilders.',
      url: verwaltungBaseUrl,
      tags: ['ummeldung', 'wohnort', 'umzug'],
      sortOrder: 201,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Wohnsitz abmelden',
      description: 'Abmeldung bei Wegzug ins Ausland.',
      url: verwaltungBaseUrl,
      tags: ['abmeldung', 'ausland', 'wohnort'],
      sortOrder: 202,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Meldebescheinigung beantragen',
      description: 'Bescheinigung über den aktuellen Wohnsitz.',
      url: verwaltungBaseUrl,
      tags: ['meldebescheinigung', 'wohnort'],
      sortOrder: 203,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Melderegisterauskunft',
      description: 'Einfache oder erweiterte Auskunft aus dem Melderegister.',
      url: verwaltungBaseUrl,
      tags: ['melderegister', 'auskunft'],
      sortOrder: 204,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Wohnungsgeberbestätigung',
      description: 'Bestätigung des Vermieters für An- oder Ummeldung.',
      url: verwaltungBaseUrl,
      tags: ['vermieter', 'bestätigung'],
      sortOrder: 205,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Pass- und Ausweisverlust melden',
      description: 'Verlustmeldung für Personalausweis oder Reisepass.',
      url: verwaltungBaseUrl,
      tags: ['verlust', 'ausweis', 'pass'],
      sortOrder: 206,
    },
    {
      kind: 'FORM',
      category: 'Meldewesen',
      title: 'Auskunftssperre beantragen',
      description: 'Schutz vor Melderegisterauskünften.',
      url: verwaltungBaseUrl,
      tags: ['datenschutz', 'auskunftssperre'],
      sortOrder: 207,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Parkerleichterung beantragen',
      description: 'Antrag auf Sonderparkausweis (z. B. Schwerbehindert).',
      url: verwaltungBaseUrl,
      tags: ['parken', 'sonderparkausweis'],
      sortOrder: 300,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Anwohnerparken',
      description: 'Antrag auf Anwohnerparkausweis.',
      url: verwaltungBaseUrl,
      tags: ['anwohner', 'parkausweis'],
      sortOrder: 301,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Verkehrsrechtliche Anordnung',
      description: 'Beantragung von Sperrungen oder Beschilderung.',
      url: verwaltungBaseUrl,
      tags: ['sperrung', 'beschilderung', 'baustelle'],
      sortOrder: 302,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Ausnahmegenehmigung Schwertransport',
      description: 'Genehmigung für Sonder- und Schwertransporte.',
      url: verwaltungBaseUrl,
      tags: ['ausnahmegenehmigung', 'transport'],
      sortOrder: 303,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Sondernutzung öffentlicher Verkehrsraum',
      description: 'Antrag für Container, Baugerüste oder Umzüge.',
      url: verwaltungBaseUrl,
      tags: ['sondernutzung', 'container', 'umzug'],
      sortOrder: 304,
    },
    {
      kind: 'FORM',
      category: 'Kfz/Verkehr',
      title: 'Straßensperrung Veranstaltungen',
      description: 'Sperrungen für Umzüge, Märkte oder Feste.',
      url: verwaltungBaseUrl,
      tags: ['veranstaltung', 'sperrung'],
      sortOrder: 305,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Bauantrag - Hinweise',
      description: 'Checkliste und Hinweise für Bauanträge.',
      url: verwaltungBaseUrl,
      tags: ['bauantrag', 'checkliste'],
      sortOrder: 400,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Anzeige Baubeginn',
      description: 'Meldung des Baubeginns an die Gemeinde.',
      url: verwaltungBaseUrl,
      tags: ['baubeginn', 'meldung'],
      sortOrder: 401,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Antrag Stellplatznachweis',
      description: 'Nachweis der notwendigen Stellplätze.',
      url: verwaltungBaseUrl,
      tags: ['stellplatz', 'parken'],
      sortOrder: 402,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Antrag Befreiung Bebauungsplan',
      description: 'Befreiung von Festsetzungen im Bebauungsplan.',
      url: verwaltungBaseUrl,
      tags: ['bebauungsplan', 'befreiung'],
      sortOrder: 403,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Sondernutzungssatzung',
      description: 'Antrag für Nutzung öffentlicher Flächen.',
      url: verwaltungBaseUrl,
      tags: ['sondernutzung', 'flächen'],
      sortOrder: 404,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Antrag Hausnummernvergabe',
      description: 'Vergabe oder Änderung von Hausnummern.',
      url: verwaltungBaseUrl,
      tags: ['hausnummer', 'adresse'],
      sortOrder: 405,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Antrag Grundstücksteilung',
      description: 'Teilung von Grundstücken und Flurstücken.',
      url: verwaltungBaseUrl,
      tags: ['grundstück', 'teilung'],
      sortOrder: 406,
    },
    {
      kind: 'FORM',
      category: 'Bauen/Wohnen',
      title: 'Wohnraumförderung',
      description: 'Antrag auf Fördermittel für Wohnraum.',
      url: verwaltungBaseUrl,
      tags: ['förderung', 'wohnraum'],
      sortOrder: 407,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Hundesteuer anmelden',
      description: 'Anmeldung eines Hundes zur Hundesteuer.',
      url: verwaltungBaseUrl,
      tags: ['hundesteuer', 'anmeldung'],
      sortOrder: 500,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Hundesteuer abmelden',
      description: 'Abmeldung bei Wegzug oder Tod des Hundes.',
      url: verwaltungBaseUrl,
      tags: ['hundesteuer', 'abmeldung'],
      sortOrder: 501,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Hundesteuer Ermäßigung',
      description: 'Antrag auf Ermäßigung der Hundesteuer.',
      url: verwaltungBaseUrl,
      tags: ['hundesteuer', 'ermäßigung'],
      sortOrder: 502,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Grundsteuer-Änderungsanzeige',
      description: 'Änderungen zu Grundstück oder Eigentum melden.',
      url: verwaltungBaseUrl,
      tags: ['grundsteuer', 'eigentuemer'],
      sortOrder: 503,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Gewerbeanmeldung',
      description: 'Anmeldung eines Gewerbebetriebs.',
      url: verwaltungBaseUrl,
      tags: ['gewerbe', 'anmeldung'],
      sortOrder: 504,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Gewerbeummeldung',
      description: 'Änderungen im Gewerbebetrieb mitteilen.',
      url: verwaltungBaseUrl,
      tags: ['gewerbe', 'ummeldung'],
      sortOrder: 505,
    },
    {
      kind: 'FORM',
      category: 'Steuern/Abgaben',
      title: 'Gewerbeabmeldung',
      description: 'Abmeldung eines Gewerbebetriebs.',
      url: verwaltungBaseUrl,
      tags: ['gewerbe', 'abmeldung'],
      sortOrder: 506,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Wohngeld beantragen',
      description: 'Antrag auf Miet- oder Lastenzuschuss.',
      url: verwaltungBaseUrl,
      tags: ['wohngeld', 'miete', 'zuschuss'],
      sortOrder: 600,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Bildung & Teilhabe',
      description: 'Leistungen für Kinder und Jugendliche.',
      url: verwaltungBaseUrl,
      tags: ['bildung', 'teilhabe', 'kinder'],
      sortOrder: 601,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Seniorenberatung',
      description: 'Anfrage zu Hilfen im Alltag.',
      url: verwaltungBaseUrl,
      tags: ['senioren', 'beratung'],
      sortOrder: 602,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Pflegeunterstützung',
      description: 'Antrag auf Unterstützung bei Pflegefällen.',
      url: verwaltungBaseUrl,
      tags: ['pflege', 'unterstützung'],
      sortOrder: 603,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Sozialpass beantragen',
      description: 'Antrag auf Ermäßigungen bei geringem Einkommen.',
      url: verwaltungBaseUrl,
      tags: ['sozialpass', 'ermäßigung'],
      sortOrder: 604,
    },
    {
      kind: 'FORM',
      category: 'Soziales',
      title: 'Unterstützung bei Wohnungsverlust',
      description: 'Kontaktformular für Beratung und Hilfe.',
      url: verwaltungBaseUrl,
      tags: ['wohnungslosigkeit', 'hilfe'],
      sortOrder: 605,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Veranstaltung anmelden',
      description: 'Anmeldung öffentlicher Veranstaltungen.',
      url: verwaltungBaseUrl,
      tags: ['veranstaltung', 'anzeige'],
      sortOrder: 700,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Lärmbeschwerde einreichen',
      description: 'Hinweis auf Lärmbelästigung oder Ruhestörung.',
      url: verwaltungBaseUrl,
      tags: ['lärm', 'beschwerde'],
      sortOrder: 701,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Fundsache melden',
      description: 'Gefundene Gegenstände im Fundbüro melden.',
      url: verwaltungBaseUrl,
      tags: ['fundbüro', 'fundsache'],
      sortOrder: 702,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Antrag Sondernutzung (Infostand)',
      description: 'Genehmigung für Infostände oder Werbeflächen.',
      url: verwaltungBaseUrl,
      tags: ['sondernutzung', 'infostand'],
      sortOrder: 703,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Antrag Feuerwerk (Kategorie F2)',
      description: 'Anzeige eines privaten Feuerwerks.',
      url: verwaltungBaseUrl,
      tags: ['feuerwerk', 'anzeige'],
      sortOrder: 704,
    },
    {
      kind: 'FORM',
      category: 'Ordnung',
      title: 'Antrag Fischereischein',
      description: 'Antrag für den Fischereischein.',
      url: verwaltungBaseUrl,
      tags: ['fischen', 'schein'],
      sortOrder: 705,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'SEPA-Lastschriftmandat',
      description: 'Einzugsermächtigung für Gebühren und Abgaben.',
      url: verwaltungBaseUrl,
      tags: ['sepa', 'lastschrift'],
      sortOrder: 800,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Kontaktformular Rathaus',
      description: 'Allgemeine Anfrage an die Verwaltung.',
      url: verwaltungBaseUrl,
      tags: ['kontakt', 'anfrage'],
      sortOrder: 801,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Nachsendeadresse mitteilen',
      description: 'Mitteilung einer neuen Zustelladresse.',
      url: verwaltungBaseUrl,
      tags: ['adresse', 'nachsende'],
      sortOrder: 802,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Reisepass beantragen',
      description: 'Beantragung eines Reisepasses.',
      url: verwaltungBaseUrl,
      tags: ['reisepass', 'ausweis'],
      sortOrder: 803,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Personalausweis beantragen',
      description: 'Beantragung oder Verlängerung des Personalausweises.',
      url: verwaltungBaseUrl,
      tags: ['personalausweis', 'ausweis'],
      sortOrder: 804,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Vollmacht zur Abholung',
      description: 'Vollmacht für die Abholung von Dokumenten.',
      url: verwaltungBaseUrl,
      tags: ['vollmacht', 'abholung'],
      sortOrder: 805,
    },
    {
      kind: 'FORM',
      category: 'Sonstiges',
      title: 'Datenschutz-Auskunft',
      description: 'Antrag auf Auskunft zu gespeicherten Daten.',
      url: verwaltungBaseUrl,
      tags: ['datenschutz', 'auskunft'],
      sortOrder: 806,
    },
  ];

  const citizenPosts = [
    {
      type: 'MARKETPLACE_LISTING',
      title: `${DEMO_PREFIX} Kinderfahrrad 20 Zoll`,
      body: 'Gut erhaltenes Fahrrad, inkl. Helm. Abholung in Hilders möglich.',
    },
    {
      type: 'MARKETPLACE_LISTING',
      title: `${DEMO_PREFIX} Gartenmöbel-Set`,
      body: 'Vier Stühle + Tisch, wetterfest. Nur Selbstabholung.',
    },
    {
      type: 'MARKETPLACE_LISTING',
      title: `${DEMO_PREFIX} Holzregal aus Massivholz`,
      body: 'Stabil und gepflegt. Maße 180x80 cm.',
    },
    {
      type: 'MARKETPLACE_LISTING',
      title: `${DEMO_PREFIX} E-Bike Anhänger`,
      body: 'Leichter Anhänger für Einkäufe, inkl. Kupplung.',
    },
    {
      type: 'USER_POST',
      title: `${DEMO_PREFIX} Suche Laufgruppe`,
      body: 'Wer läuft morgens in der Rhön? Ich suche eine entspannte Runde.',
    },
    {
      type: 'USER_POST',
      title: `${DEMO_PREFIX} Nachbarschaftsfrage`,
      body: 'Kennt jemand einen guten Elektriker in der Nähe?',
    },
    {
      type: 'USER_POST',
      title: `${DEMO_PREFIX} Tipps fürs Sommerfest`,
      body: 'Ideen für kinderfreundliche Spiele gesucht.',
    },
    {
      type: 'HELP_REQUEST',
      title: `${DEMO_PREFIX} Hilfe beim Möbeltragen`,
      body: 'Wir brauchen am Samstag zwei helfende Hände für einen Umzugskarton.',
    },
    {
      type: 'HELP_REQUEST',
      title: `${DEMO_PREFIX} Gartenbewässerung in den Ferien`,
      body: 'Suche jemanden, der meine Pflanzen für 10 Tage gießt.',
    },
    {
      type: 'HELP_OFFER',
      title: `${DEMO_PREFIX} Unterstützung bei Formularen`,
      body: 'Ich helfe gerne beim Ausfüllen von Anträgen oder Online-Formularen.',
    },
    {
      type: 'HELP_OFFER',
      title: `${DEMO_PREFIX} Fahrdienst zum Einkaufen`,
      body: 'Biete Fahrten zum Supermarkt an, meldet euch gerne.',
    },
    {
      type: 'MOVING_CLEARANCE',
      title: `${DEMO_PREFIX} Haushaltsauflösung Küche`,
      body: 'Geschirr, Töpfe und Kleingeräte abzugeben. Abholung Mo-Fr.',
    },
    {
      type: 'MOVING_CLEARANCE',
      title: `${DEMO_PREFIX} Kellerfundstücke`,
      body: 'Regale, Kisten und Werkzeug – alles günstig abzugeben.',
    },
    {
      type: 'CAFE_MEETUP',
      title: `${DEMO_PREFIX} Kaffee & Klön bei Leni`,
      body: 'Lockeres Treffen bei Kaffee und Kuchen im Dorfzentrum.',
      metadata: {
        dateTime: addDays(now, 5, 15),
        location: 'Café Leni',
      },
    },
    {
      type: 'CAFE_MEETUP',
      title: `${DEMO_PREFIX} Frühstücksrunde am Markt`,
      body: 'Wir treffen uns zum gemeinsamen Frühstück. Jeder ist willkommen.',
      metadata: {
        dateTime: addDays(now, 12, 9),
        location: 'Marktplatz Hilders',
      },
    },
    {
      type: 'KIDS_MEETUP',
      title: `${DEMO_PREFIX} Kinder-Entdeckerclub`,
      body: 'Treffpunkt für kleine Entdecker mit Schatzsuche und Spielen.',
      metadata: {
        dateTime: addDays(now, 7, 16),
        location: 'Spielplatz am Auengrund',
      },
    },
    {
      type: 'KIDS_MEETUP',
      title: `${DEMO_PREFIX} Bastelnachmittag`,
      body: 'Bastelstationen und kurze Geschichten für Kinder ab 5 Jahren.',
      metadata: {
        dateTime: addDays(now, 16, 15),
        location: 'Familienzentrum Hilders',
      },
    },
    {
      type: 'APARTMENT_SEARCH',
      title: `${DEMO_PREFIX} 2-Zimmer Wohnung gesucht`,
      body: 'Junges Paar sucht eine 2-Zimmer-Wohnung in Hilders ab sofort.',
      metadata: {
        type: 'SEARCH',
        contact: 'wohnung@hilders-demo.de',
      },
    },
    {
      type: 'APARTMENT_SEARCH',
      title: `${DEMO_PREFIX} 3-Zimmer Wohnung anzubieten`,
      body: 'Helle Wohnung mit Balkon, 75qm, zentrale Lage.',
      metadata: {
        type: 'OFFER',
        contact: 'vermietung@hilders-demo.de',
      },
    },
    {
      type: 'APARTMENT_SEARCH',
      title: `${DEMO_PREFIX} WG-Zimmer frei`,
      body: 'Möbliertes Zimmer in ruhiger Lage, ab nächsten Monat verfügbar.',
      metadata: {
        type: 'OFFER',
        contact: 'wg@hilders-demo.de',
      },
    },
    {
      type: 'RIDE_SHARING',
      title: `${DEMO_PREFIX} Mitfahrgelegenheit nach Fulda`,
      body: 'Fahre Montag 7:30 nach Fulda, Rückfahrt 16:30. Zwei Plätze frei.',
      metadata: {
        dateTime: addDays(now, 2, 7),
        route: 'Hilders → Fulda',
      },
    },
    {
      type: 'RIDE_SHARING',
      title: `${DEMO_PREFIX} Fahrgemeinschaft zum Wochenmarkt`,
      body: 'Samstagvormittag Richtung Tann, Plätze vorhanden.',
      metadata: {
        dateTime: addDays(now, 9, 9),
        route: 'Hilders → Tann',
      },
    },
    {
      type: 'VOLUNTEERING',
      title: `${DEMO_PREFIX} Helfer für Dorffest gesucht`,
      body: 'Unterstützung beim Aufbau und an den Ständen gesucht.',
    },
    {
      type: 'VOLUNTEERING',
      title: `${DEMO_PREFIX} Lesepaten für die Bücherei`,
      body: 'Wir suchen ehrenamtliche Vorleser für Kindergruppen.',
    },
    {
      type: 'VOLUNTEERING',
      title: `${DEMO_PREFIX} Umweltaktion am Bach`,
      body: 'Gemeinsames Aufräumen entlang der Ulster.',
    },
    {
      type: 'GIVEAWAY',
      title: `${DEMO_PREFIX} Bücherkiste abzugeben`,
      body: 'Gemischte Romane und Kinderbücher, gerne abholen.',
    },
    {
      type: 'GIVEAWAY',
      title: `${DEMO_PREFIX} Pflanzenableger`,
      body: 'Ableger von Zimmerpflanzen, einfach melden.',
    },
    {
      type: 'GIVEAWAY',
      title: `${DEMO_PREFIX} Wintersachen`,
      body: 'Jacken und Mützen in gutem Zustand, Größen M/L.',
    },
    {
      type: 'SKILL_EXCHANGE',
      title: `${DEMO_PREFIX} Gitarrenunterricht gegen Sprachhilfe`,
      body: 'Biete Anfängerunterricht, suche Unterstützung in Spanisch.',
    },
    {
      type: 'SKILL_EXCHANGE',
      title: `${DEMO_PREFIX} Reparaturhilfe gesucht`,
      body: 'Kann bei Fahrradreparaturen helfen, suche Hilfe bei IT-Themen.',
    },
    {
      type: 'SKILL_EXCHANGE',
      title: `${DEMO_PREFIX} Backkurs tauschen`,
      body: 'Biete Brotbacken, suche Yoga- oder Fitness-Tipps.',
    },
  ];

  const allTypes = [
    'OFFICIAL_EVENT',
    'OFFICIAL_NEWS',
    'OFFICIAL_WARNING',
    'MARKETPLACE_LISTING',
    'USER_POST',
    'HELP_REQUEST',
    'HELP_OFFER',
    'MOVING_CLEARANCE',
    'CAFE_MEETUP',
    'KIDS_MEETUP',
    'APARTMENT_SEARCH',
    'RIDE_SHARING',
    'VOLUNTEERING',
    'GIVEAWAY',
    'SKILL_EXCHANGE',
  ];

  await deleteDemoPosts(staffToken, allTypes);
  await createPosts(staffToken, [
    ...officialEvents,
    ...officialNews,
    ...officialWarnings,
    ...citizenPosts,
  ]);

  await seedVerwaltungItems([...verwaltungLinks, ...verwaltungForms]);

  const tourismItems = [
    {
      type: 'HIKING_ROUTE',
      title: `${DEMO_PREFIX} Ulstertal-Runde`,
      body: 'Leichte Rundtour entlang der Ulster mit herrlichen Ausblicken.',
      metadata: {
        location: 'Start am Parkplatz Kaskadenschlucht',
        address: 'Kaskadenschlucht, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/tourismus',
        tags: ['leicht', 'familienfreundlich', 'aussicht'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'HIKING_ROUTE',
      title: `${DEMO_PREFIX} Buchschirm-Trail`,
      body: 'Anspruchsvolle Tour mit Panoramablick auf die Rhön.',
      metadata: {
        location: 'Start am Rhönklubhaus',
        address: 'Buchschirmweg, 36115 Hilders',
        websiteUrl: 'https://www.rhoen.de',
        tags: ['berg', 'panorama', 'sportlich'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'HIKING_ROUTE',
      title: `${DEMO_PREFIX} Moorpfad Erlebnisweg`,
      body: 'Naturpfad durch die Hochmoore mit Infotafeln.',
      metadata: {
        location: 'Rotes Moor',
        address: 'Rotes Moor, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/natur',
        tags: ['natur', 'infotafeln', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'HIKING_ROUTE',
      title: `${DEMO_PREFIX} Dörfertour Hilders`,
      body: 'Entspannte Strecke durch die Ortsteile mit Einkehrmöglichkeiten.',
      metadata: {
        location: 'Marktplatz Hilders',
        address: 'Marktplatz, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/dorf',
        tags: ['dorf', 'einkehr', 'kultur'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'HIKING_ROUTE',
      title: `${DEMO_PREFIX} Rhönblick-Pfade`,
      body: 'Rundweg mit spektakulären Blicken in die Kuppenrhön.',
      metadata: {
        location: 'Aussichtspunkt Rhönblick',
        address: 'Rhönblickweg, 36115 Hilders',
        websiteUrl: 'https://www.rhoen.info',
        tags: ['panorama', 'fotospots', 'mittel'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Kaskadenschlucht`,
      body: 'Naturdenkmal mit Wasserfällen und Holzstegen.',
      metadata: {
        location: 'Kaskadenschlucht',
        address: 'Kaskadenschlucht, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/sehenswertes',
        tags: ['natur', 'wasserfall'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Rhönmuseum`,
      body: 'Regionalmuseum mit Ausstellungen zur Rhön.',
      metadata: {
        location: 'Museumsstraße 3',
        address: 'Museumsstraße 3, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/museum',
        tags: ['kultur', 'museum'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Aussichtsturm Buchschirm`,
      body: 'Beliebter Aussichtsturm mit Rundblick.',
      metadata: {
        location: 'Buchschirm',
        address: 'Buchschirm, 36115 Hilders',
        websiteUrl: 'https://www.rhoen.de',
        tags: ['aussicht', 'wandern'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Ulsterquelle`,
      body: 'Quellgebiet der Ulster mit Rastplatz.',
      metadata: {
        location: 'Ulsterquelle',
        address: 'Ulsterquelle, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/natur',
        tags: ['quelle', 'natur'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Dorfkirche Hilders`,
      body: 'Historische Kirche im Ortszentrum.',
      metadata: {
        location: 'Kirchstraße 2',
        address: 'Kirchstraße 2, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/kirche',
        tags: ['geschichte', 'architektur'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Naturlehrpfad Auengrund`,
      body: 'Lehrpfad mit Infotafeln zu Flora und Fauna.',
      metadata: {
        location: 'Auengrund',
        address: 'Auengrund, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/natur',
        tags: ['lehrpfad', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Heimatstube Brand`,
      body: 'Kleine Ausstellung zur Dorfgeschichte.',
      metadata: {
        location: 'Ortsteil Brand',
        address: 'Brand 12, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/heimat',
        tags: ['geschichte', 'tradition'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'SIGHT',
      title: `${DEMO_PREFIX} Kapelle Simmershausen`,
      body: 'Kleine Kapelle mit weitem Blick über das Tal.',
      metadata: {
        location: 'Simmershausen',
        address: 'Simmershausen, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/kapellen',
        tags: ['ruhe', 'aussicht'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Freibad Hilders`,
      body: 'Beheiztes Freibad mit Familienbereich.',
      metadata: {
        location: 'Am Freibad 1',
        address: 'Am Freibad 1, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/freibad',
        tags: ['schwimmen', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Minigolfanlage Rhön`,
      body: '18-Bahnen Minigolf für Groß und Klein.',
      metadata: {
        location: 'Freizeitpark Hilders',
        address: 'Freizeitpark 2, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/freizeit',
        tags: ['minigolf', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Kletterwald Rhön`,
      body: 'Kletterparcours mit unterschiedlichen Schwierigkeitsstufen.',
      metadata: {
        location: 'Kletterwald',
        address: 'Waldweg 5, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/kletterwald',
        tags: ['klettern', 'abenteuer'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Rhönrad-Workshop`,
      body: 'Schnupperkurs für Rhönrad und Akrobatik.',
      metadata: {
        location: 'Sporthalle Hilders',
        address: 'Sporthallenweg 3, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/sport',
        tags: ['sport', 'workshop'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Picknickwiese Auengrund`,
      body: 'Große Wiese mit Grillplatz und Spielbereich.',
      metadata: {
        location: 'Auengrund',
        address: 'Auengrund, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/picknick',
        tags: ['picknick', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'LEISURE',
      title: `${DEMO_PREFIX} Fahrradverleih Rhön`,
      body: 'Verleih von E-Bikes und Tourenrädern.',
      metadata: {
        location: 'Bahnhofstraße 8',
        address: 'Bahnhofstraße 8, 36115 Hilders',
        websiteUrl: 'https://www.hilders.de/fahrrad',
        tags: ['radfahren', 'service'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Gasthaus Rhönblick`,
      body: 'Regionale Küche mit saisonalen Spezialitäten.',
      metadata: {
        location: 'Kirchstraße 10',
        address: 'Kirchstraße 10, 36115 Hilders',
        websiteUrl: 'https://www.rhoenblick-hilders.de',
        openingHours: 'Mo-Sa 11:30-21:00, So 11:30-19:00',
        tags: ['regional', 'familie'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Café Leni`,
      body: 'Hausgemachte Kuchen, Frühstück und kleine Snacks.',
      metadata: {
        location: 'Marktplatz 4',
        address: 'Marktplatz 4, 36115 Hilders',
        websiteUrl: 'https://www.cafe-leni.de',
        openingHours: 'Di-So 08:00-18:00',
        tags: ['café', 'kuchen'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Rhönburger Station`,
      body: 'Burger, Salate und hausgemachte Limonaden.',
      metadata: {
        location: 'Bahnhofstraße 12',
        address: 'Bahnhofstraße 12, 36115 Hilders',
        websiteUrl: 'https://www.rhoenburger.de',
        openingHours: 'Mo-Sa 12:00-21:30',
        tags: ['burger', 'modern'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Waldschänke am Moor`,
      body: 'Rustikale Küche mit Blick auf das Hochmoor.',
      metadata: {
        location: 'Rotes Moor 2',
        address: 'Rotes Moor 2, 36115 Hilders',
        websiteUrl: 'https://www.waldschaenke-moor.de',
        openingHours: 'Mi-So 11:00-20:00',
        tags: ['rustikal', 'ausblick'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Pizzeria Ulsterblick`,
      body: 'Italienische Küche, Pizza aus dem Steinofen.',
      metadata: {
        location: 'Ulsterweg 6',
        address: 'Ulsterweg 6, 36115 Hilders',
        websiteUrl: 'https://www.ulsterblick-pizza.de',
        openingHours: 'Di-So 17:00-22:00',
        tags: ['italienisch', 'pizza'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Bistro Marktzeit`,
      body: 'Schnelle Gerichte, Salate und Suppen.',
      metadata: {
        location: 'Marktplatz 1',
        address: 'Marktplatz 1, 36115 Hilders',
        websiteUrl: 'https://www.marktzeit-bistro.de',
        openingHours: 'Mo-Fr 11:00-17:00',
        tags: ['bistro', 'mittags'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Landhaus Küche`,
      body: 'Traditionelle Rhöner Spezialitäten und saisonale Gerichte.',
      metadata: {
        location: 'Hauptstraße 18',
        address: 'Hauptstraße 18, 36115 Hilders',
        websiteUrl: 'https://www.landhaus-kueche.de',
        openingHours: 'Do-Sa 17:30-22:00, So 11:30-19:00',
        tags: ['tradition', 'regional'],
      },
      status: 'PUBLISHED',
    },
    {
      type: 'RESTAURANT',
      title: `${DEMO_PREFIX} Rhönblick Alm`,
      body: 'Alpenküche, Brettljausen und Weinauswahl.',
      metadata: {
        location: 'Aussichtsweg 3',
        address: 'Aussichtsweg 3, 36115 Hilders',
        websiteUrl: 'https://www.rhoenblick-alm.de',
        openingHours: 'Mi-So 12:00-21:00',
        tags: ['alpenküche', 'ausblick'],
      },
      status: 'PUBLISHED',
    },
  ];

  const tourismTypes = ['HIKING_ROUTE', 'SIGHT', 'LEISURE', 'RESTAURANT'];
  await deleteDemoTourism(tourismTypes);
  await createTourism(tourismItems);

  await seedTouristCodes();

  // eslint-disable-next-line no-console
  console.log(`Seed abgeschlossen für Tenant ${TENANT}.`);
};

seed().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
