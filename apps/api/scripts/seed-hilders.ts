import { MunicipalityFormsService } from '../src/municipality/forms/municipality-forms.service';
import { MunicipalityProfileService } from '../src/municipality/profile/municipality-profile.service';
import { TourismService } from '../src/tourism/tourism.service';
import { tourismSeedItems } from './tourism-hilders.data';

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
