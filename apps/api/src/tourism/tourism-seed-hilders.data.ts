import { TourismItemType } from './tourism.types';

export const tourismSeedItems: Array<{
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
