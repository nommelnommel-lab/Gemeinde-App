import '../models/start_feed_preview_item.dart';

class StartFeedExtrasService {
  Future<List<StartFeedPreviewItem>> getCafeTreff() async {
    return List<StartFeedPreviewItem>.unmodifiable(_cafeTreff);
  }

  Future<List<StartFeedPreviewItem>> getSeniorenHilfe() async {
    return List<StartFeedPreviewItem>.unmodifiable(_seniorenHilfe);
  }

  Future<List<StartFeedPreviewItem>> getFlohmarkt() async {
    return List<StartFeedPreviewItem>.unmodifiable(_flohmarkt);
  }

  Future<List<StartFeedPreviewItem>> getUmzugEntruempelung() async {
    return List<StartFeedPreviewItem>.unmodifiable(_umzugEntruempelung);
  }

  Future<List<StartFeedPreviewItem>> getKinderSpielen() async {
    return List<StartFeedPreviewItem>.unmodifiable(_kinderSpielen);
  }
}

final List<StartFeedPreviewItem> _cafeTreff = [
  StartFeedPreviewItem(
    title: 'Frühstücksrunde im Café am Markt',
    subtitle: 'Di, 09:30 · Café am Markt',
  ),
  StartFeedPreviewItem(
    title: 'Kaffee & Kuchen Nachmittag',
    subtitle: 'Do, 15:00 · Gemeindezentrum',
  ),
  StartFeedPreviewItem(
    title: 'Treffpunkt für neue Nachbarn',
    subtitle: 'Sa, 10:30 · Familiencafé',
  ),
];

final List<StartFeedPreviewItem> _seniorenHilfe = [
  StartFeedPreviewItem(
    title: 'Begleitdienst zum Arzt',
    subtitle: 'Freie Termine in dieser Woche',
  ),
  StartFeedPreviewItem(
    title: 'Telefonkette gegen Einsamkeit',
    subtitle: 'Mitmachen oder Hilfe anfragen',
  ),
];

final List<StartFeedPreviewItem> _flohmarkt = [
  StartFeedPreviewItem(
    title: 'Hofflohmarkt in der Gartenstraße',
    subtitle: 'Sa, 11:00 · 20 Stände',
  ),
  StartFeedPreviewItem(
    title: 'Kinderkleidung & Spielzeug',
    subtitle: 'So, 09:00 · Turnhalle',
  ),
  StartFeedPreviewItem(
    title: 'Bücher-Tauschbörse',
    subtitle: 'Jeden Freitag · Bücherei',
  ),
];

final List<StartFeedPreviewItem> _umzugEntruempelung = [
  StartFeedPreviewItem(
    title: 'Helfer für Umzug gesucht',
    subtitle: '2 Personen für Samstagvormittag',
  ),
  StartFeedPreviewItem(
    title: 'Entrümpelungsaktion im Quartier',
    subtitle: 'Jetzt Mitstreiter finden',
  ),
];

final List<StartFeedPreviewItem> _kinderSpielen = [
  StartFeedPreviewItem(
    title: 'Spielplatz-Treff am See',
    subtitle: 'Mi, 16:00 · Für 3-6 Jahre',
  ),
  StartFeedPreviewItem(
    title: 'Eltern-Kind-Spielgruppe',
    subtitle: 'Fr, 10:00 · Gemeindehaus',
  ),
];
