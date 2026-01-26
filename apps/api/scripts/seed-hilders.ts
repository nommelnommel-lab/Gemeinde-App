import { MunicipalityFormsService } from '../src/municipality/forms/municipality-forms.service';
import { MunicipalityProfileService } from '../src/municipality/profile/municipality-profile.service';
import { TourismService } from '../src/tourism/tourism.service';
import { TourismItemType } from '../src/tourism/tourism.types';

const tenantId = process.env.TENANT ?? 'hilders-demo';

const profilePayload = {
  name: 'Marktgemeinde Hilders',
  address: {
    street: 'Kirchstraße 2-6',
    zip: '36115',
    city: 'Hilders',
  },
  phone: '06681 9608-0',
  fax: '06681 9608-22',
  email: 'gemeinde@hilders.de',
  websiteUrl: 'https://www.hilders.de',
  openingHours: [
    {
      weekday: 'Mo',
      slots: [
        { from: '08:30', to: '12:00' },
        { from: '14:00', to: '16:00' },
      ],
    },
    {
      weekday: 'Di',
      slots: [
        { from: '08:30', to: '12:00' },
        { from: '14:00', to: '16:00' },
      ],
    },
    { weekday: 'Mi', slots: [], note: 'geschlossen' },
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
  importantLinks: [
    { label: 'Kontakt', url: 'https://www.hilders.de/kontakt' },
    {
      label: 'Online-Rathaus',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus',
    },
    {
      label: 'Formulare & Vordrucke (alle)',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/formulare-vordrucke-alle',
    },
    {
      label: 'Bürgerbus',
      url: 'https://www.hilders.de/rathaus/buergerservice/buergerbus',
    },
    {
      label: 'Veranstaltungskalender',
      url: 'https://www.hilders.de/3/veranstaltungen/veranstaltungskalender#/veranstaltungen',
    },
    {
      label: 'Amtliche Bekanntmachungen',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/amtliche-bekanntmachungen',
    },
    {
      label: 'Bauleitplanung',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/bauleitplanung',
    },
    {
      label: 'Satzungen und Ortsrecht',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/satzungen-und-ortsrecht',
    },
    {
      label: 'Steuern und Gebühren',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/steuern-und-gebuehren',
    },
    {
      label: 'Wahlen',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/wahlen',
    },
    {
      label: 'Personalausweis & Reisepass',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/personalausweis-reisepass',
    },
    {
      label: 'Wohnungsgeberbestätigung',
      url: 'https://www.hilders.de/rathaus/buergerservice/online-rathaus/wohnungsgeberbestaetigung',
    },
  ],
  emergencyNumbers: [
    { label: 'Polizei', number: '110' },
    { label: 'Feuerwehr / Rettungsdienst', number: '112' },
    { label: 'Ärztlicher Bereitschaftsdienst', number: '116117' },
  ],
};

const formLinks = [
  {
    category: 'Allgemeine Formulare',
    title: 'SEPA-Lastschriftmandat',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/SEPA_Lastschriftmandat.pdf',
  },
  {
    category: 'Abfallentsorgung',
    title: 'Anmeldung/Änderung/Abmeldung Abfallbehälter',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/53710_AEnderungAbfallbehaelterV1.1.pdf',
  },
  {
    category: 'Abfallentsorgung',
    title: 'Befreiung Bioabfallbehälter',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/53710_BefreiungBioabfallbehaelterV1.0.pdf',
  },
  {
    category: 'Abwasserbeseitigung',
    title: 'Leerung Kleinkläranlagen und Sammelgruben',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/53810_LeerungKleinklaeranlagenSammelgrubenV1.1.pdf',
  },
  {
    category: 'Abwasserbeseitigung',
    title: 'Änderungsanzeige / Flächenauswertung durch Eigentümer',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__aenderungsanzeige_bzw_flaechenauswertung_durch_eigentuemer.pdf',
  },
  {
    category: 'Einwohnermeldeamt',
    title: 'Wohnungsgeberbestätigung (Formular PDF)',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__einwohnermeldeamt_wohnungsgeberbestaetigung.pdf',
  },
  {
    category: 'Einwohnermeldeamt',
    title: 'Einverständniserklärung Ausstellung Ausweisdokument',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/Einverstaendniserklaerung.pdf',
  },
  {
    category: 'Einwohnermeldeamt',
    title: 'Vollmacht Abholung Ausweisdokument',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__Vollmacht_Abholung_Ausweisdokument.pdf',
  },
  {
    category: 'Gewerbe',
    title: 'Gewerbeanmeldung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__gewerbeamt_gewerbeanmeldung.pdf',
  },
  {
    category: 'Gewerbe',
    title: 'Gewerbeummeldung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__gewerbeamt_gewerbeummeldung.pdf',
  },
  {
    category: 'Gewerbe',
    title: 'Gewerbeabmeldung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__gewerbeamt_gewerbeabmeldung.pdf',
  },
  {
    category: 'Gewerbe',
    title: 'Eintrag im gemeindlichen Branchenverzeichnis',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__homepage_eintragung_branchenverzeichnis.pdf',
  },
  {
    category: 'Hilders-Gutscheine',
    title: 'Anmeldeformular Hilders-Gutschein',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/57110_AnmeldeformularHildersgutscheinV1.0.pdf',
  },
  {
    category: 'Hilders-Gutscheine',
    title: 'Erstattungsantrag Hilders-Gutschein',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/57110_ErstattungsantragHildersgutscheinV1.0.pdf',
  },
  {
    category: 'Hundesteuer',
    title: 'Hundesteuer Anmeldung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/61110_HundesteuerAnmeldungV1.1.pdf',
  },
  {
    category: 'Hundesteuer',
    title: 'Hundesteuer Abmeldung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/61110_HundesteuerAbmeldungV1.1.pdf',
  },
  {
    category: 'Immobilienverzeichnis',
    title: 'Meldung einer freien Mietwohnung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__meldung_immobilie.pdf',
  },
  {
    category: 'Spielapparatesteuer',
    title: 'Steuererklärung Spielapparatesteuer',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/61110_SteuererklaerungSpielapparatesteuerV1.0.pdf',
  },
  {
    category: 'Straßensperrung',
    title: 'Antrag Verkehrssichernde Maßnahmen (§45 StVO) bei Baustellen',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__antrag-auf-anordnung-verkehrsregelnder-massnahmen-nach-paragraph-45-StVO-bei-baustellen.pdf',
  },
  {
    category: 'Straßensperrung',
    title: 'Antrag Straßensperrung (§29 StVO) bei Veranstaltungen',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__antrag-auf-strassensperrung-nach-paragraph-29-StVO-bei-veranstaltungen.pdf',
  },
  {
    category: 'Tourismusabgabe',
    title: 'Steuererklärung Tourismusabgabe',
    url: 'https://www.hilders.de/fileadmin/user_upload/Rathaus/57510_SteuererklaerungTourismusabgabeV1.3.pdf',
  },
  {
    category: 'Veranstaltungen',
    title: 'Ausschankgenehmigung',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/20240513_Formular_Ausschankgenehmigung_aktuell.pdf',
  },
  {
    category: 'Veranstaltungen',
    title: 'Veranstaltungsmeldung (Veranstaltungskalender)',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__veranstaltungsmeldung_veranstaltungskalender.pdf',
  },
  {
    category: 'Veranstaltungen',
    title: 'Absicherung einer Veranstaltung durch die Freiwillige Feuerwehr',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/Antrag_Absicherung_Prozessionen_-_PDF_.pdf',
  },
  {
    category: 'Veranstaltungen',
    title: 'Ausnahmegenehmigung für Trauungen',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/Antrag_auf_Ausnahmegenehmigung____46_StVO_Hilders.pdf',
  },
  {
    category: 'Zweckfeuer / Brauchtumsfeuer / Feuerwerk',
    title: 'Anzeige Zweckfeuer',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/Formular_Anzeige_Zweckfeuer.pdf',
  },
  {
    category: 'Zweckfeuer / Brauchtumsfeuer / Feuerwerk',
    title: 'Anzeige Brauchtumsfeuer',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__brauchtumsfeuer-anzeige_ausfuellbar.pdf',
  },
  {
    category: 'Zweckfeuer / Brauchtumsfeuer / Feuerwerk',
    title: 'Antrag Feuerwerk (Klasse 2)',
    url: 'https://www.hilders.de/fileadmin/user_upload/Formulare/formular__ordnungsamt_antrag_feuerwerk_klasse2.pdf',
  },
];

const tourismSeedItems: Array<{
  type: TourismItemType;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
}> = [
  {
    type: 'HIKING_ROUTE',
    title: 'Rhönblick-Runde',
    body: 'Panoramaweg mit weiten Ausblicken über die Rhön. Start am Marktplatz, mehrere Rastplätze entlang der Route.',
    metadata: {
      tags: ['Panorama', 'Rundweg'],
      externalLink: 'https://www.hilders.de/tourismus/wandern/rhoenblick',
    },
  },
  {
    type: 'HIKING_ROUTE',
    title: 'Ulstertal-Trail',
    body: 'Leichter Talweg entlang der Ulster mit familienfreundlichen Abschnitten und Naturbeobachtung.',
    metadata: {
      tags: ['Familie', 'Fluss'],
      externalLink: 'https://www.hilders.de/tourismus/wandern/ulstertal',
    },
  },
  {
    type: 'HIKING_ROUTE',
    title: 'Gipfelrunde Hohe Rhön',
    body: 'Sportliche Rundtour über die Höhenzüge mit markanten Aussichtspunkten.',
    metadata: {
      tags: ['Bergtour', 'Aussicht'],
      externalLink: 'https://www.hilders.de/tourismus/wandern/gipfelrunde',
    },
  },
  {
    type: 'HIKING_ROUTE',
    title: 'Quellenweg Batten',
    body: 'Themenweg zu den Quellen der Rhön mit Infotafeln und schattigen Passagen.',
    metadata: {
      tags: ['Themenweg', 'Natur'],
      externalLink: 'https://www.hilders.de/tourismus/wandern/quellenweg',
    },
  },
  {
    type: 'HIKING_ROUTE',
    title: 'Dorfspaziergang Eckweisbach',
    body: 'Kurzer Spazierweg durch den Ortskern mit historischen Stationen.',
    metadata: {
      tags: ['Dorf', 'Kultur'],
      externalLink: 'https://www.hilders.de/tourismus/wandern/eckweisbach',
    },
  },
  {
    type: 'SIGHT',
    title: 'Guckaisee',
    body: 'Beliebter Ausflugsort mit See, Einkehrmöglichkeit und Rundweg.',
    metadata: {
      address: 'Guckaisee, 36115 Hilders',
      websiteUrl: 'https://www.hilders.de/tourismus/ausflugsziele/guckaisee',
    },
  },
  {
    type: 'SIGHT',
    title: 'Schwarzes Moor',
    body: 'Naturschutzgebiet mit Bohlenwegen und Aussichtsturm.',
    metadata: {
      address: 'Schwarzes Moor, 97650 Fladungen',
      websiteUrl: 'https://www.biosphaerenreservat-rhoen.de',
    },
  },
  {
    type: 'SIGHT',
    title: 'Burg Ebersburg',
    body: 'Burgruine mit Blick über das Ulstertal.',
    metadata: {
      address: 'Burg Ebersburg, 36115 Hilders',
      externalLink: 'https://www.hilders.de/tourismus/ausflugsziele/burg-ebersburg',
    },
  },
  {
    type: 'SIGHT',
    title: 'Rhöner Segelflugplatz Wasserkuppe',
    body: 'Deutschlands höchster Segelflugplatz mit Museum und Aussicht.',
    metadata: {
      address: 'Wasserkuppe, 36129 Gersfeld',
      websiteUrl: 'https://www.wasserkuppe.de',
    },
  },
  {
    type: 'SIGHT',
    title: 'Naturpfad Lahrbacher See',
    body: 'Spazierweg um den See mit Infotafeln zu Flora und Fauna.',
    metadata: {
      address: 'Lahrbacher See, 36115 Hilders',
      externalLink: 'https://www.hilders.de/tourismus/ausflugsziele/lahrbacher-see',
    },
  },
  {
    type: 'SIGHT',
    title: 'Ulstertal Radweg Aussichtspunkt',
    body: 'Aussichtspunkt mit Blick ins Tal, ideal für eine kurze Pause.',
    metadata: {
      address: 'Ulstertalradweg, 36115 Hilders',
    },
  },
  {
    type: 'SIGHT',
    title: 'Heimatmuseum Hilders',
    body: 'Kleines Museum zur Ortsgeschichte und regionalen Handwerkskunst.',
    metadata: {
      address: 'Kirchstraße 2, 36115 Hilders',
      openingHours: 'Sa & So 14:00-17:00',
      websiteUrl: 'https://www.hilders.de/tourismus/ausflugsziele/heimatmuseum',
    },
  },
  {
    type: 'SIGHT',
    title: 'Rhönblick-Panoramasteg',
    body: 'Holzsteg mit Rundblick über die Rhönlandschaft.',
    metadata: {
      address: 'Panoramasteg, 36115 Hilders',
    },
  },
  {
    type: 'LEISURE',
    title: 'Freibad Hilders',
    body: 'Familienfreundliches Freibad mit Liegewiese und Snackangebot.',
    metadata: {
      address: 'Schwimmbadstraße 1, 36115 Hilders',
      openingHours: 'Mo-So 09:00-19:00',
      websiteUrl: 'https://www.hilders.de/tourismus/freizeit/freibad',
    },
  },
  {
    type: 'LEISURE',
    title: 'E-Bike Verleih Rhön',
    body: 'E-Bike Verleih für Tagesausflüge in der Rhön.',
    metadata: {
      address: 'Bahnhofstraße 12, 36115 Hilders',
      phone: '06681 5555',
      websiteUrl: 'https://www.hilders.de/tourismus/freizeit/ebike',
    },
  },
  {
    type: 'LEISURE',
    title: 'Naturerlebnis-Spielplatz',
    body: 'Abenteuerspielplatz mit Kletterelementen und Wasserspielen.',
    metadata: {
      address: 'Am Park, 36115 Hilders',
    },
  },
  {
    type: 'LEISURE',
    title: 'Winterrodelbahn',
    body: 'Saisonale Rodelbahn mit kleinen Hügeln und Blick ins Tal.',
    metadata: {
      address: 'Rodelhang, 36115 Hilders',
      openingHours: 'Bei Schneelage',
    },
  },
  {
    type: 'LEISURE',
    title: 'Rhön-Fotospot Tour',
    body: 'Geführte Tour zu den schönsten Fotospots der Region.',
    metadata: {
      address: 'Tourist-Info Hilders',
      websiteUrl: 'https://www.hilders.de/tourismus/freizeit/fototour',
    },
  },
  {
    type: 'LEISURE',
    title: 'Kanuverleih Ulster',
    body: 'Geführte Kanutouren auf der Ulster mit Einweisung.',
    metadata: {
      address: 'Ulsterweg 5, 36115 Hilders',
      phone: '06681 7777',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Gasthof Rhönblick',
    body: 'Regionale Küche mit saisonalen Spezialitäten.',
    metadata: {
      address: 'Rhönstraße 10, 36115 Hilders',
      phone: '06681 1111',
      openingHours: 'Di-So 11:30-21:00',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Café Ulsterwiese',
    body: 'Café mit hausgemachten Kuchen und Terrasse.',
    metadata: {
      address: 'Ulsterweg 3, 36115 Hilders',
      openingHours: 'Mi-So 09:00-18:00',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Bergstube Batten',
    body: 'Gemütliche Stube mit Rhöner Tapas und Vesperkarte.',
    metadata: {
      address: 'Dorfplatz 2, 36115 Hilders',
      phone: '06681 2222',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Landgasthof Ebersburg',
    body: 'Rustikale Küche und kleiner Biergarten.',
    metadata: {
      address: 'Burgweg 1, 36115 Hilders',
      openingHours: 'Do-So 12:00-20:00',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Pizzeria La Rhön',
    body: 'Pizza, Pasta und Salate für den schnellen Hunger.',
    metadata: {
      address: 'Marktstraße 5, 36115 Hilders',
      phone: '06681 3333',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Bäckerei Kaffeekranz',
    body: 'Frühstück und Snacks mit lokalen Backwaren.',
    metadata: {
      address: 'Kirchstraße 8, 36115 Hilders',
      openingHours: 'Mo-Sa 06:30-15:00',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Rhönalm Hütte',
    body: 'Hüttenküche mit Brotzeiten und regionalen Getränken.',
    metadata: {
      address: 'Rhönalmweg 1, 36115 Hilders',
      openingHours: 'Fr-So 11:00-19:00',
    },
  },
  {
    type: 'RESTAURANT',
    title: 'Streetfood Rhönmobil',
    body: 'Wechselnde Standorte mit Snacks und kleinen Gerichten.',
    metadata: {
      address: 'Marktplatz Hilders',
      openingHours: 'Do-Sa 12:00-18:00',
      websiteUrl: 'https://www.hilders.de/tourismus/gastro/foodtruck',
    },
  },
];

const seed = async () => {
  const profileService = new MunicipalityProfileService();
  const formsService = new MunicipalityFormsService();
  const tourismService = new TourismService();

  await profileService.upsertProfile(tenantId, profilePayload);
  await formsService.upsertMany(tenantId, formLinks);
  await tourismService.seedDemo(tenantId, tourismSeedItems);

  // eslint-disable-next-line no-console
  console.log(`Seeded municipality profile, forms, and tourism for ${tenantId}.`);
};

seed().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
