# Demo Steps (DE)

## Seed-Daten
```bash
# Hilders Seed
npm --prefix apps/api run seed:hilders

# Demo Seed
npm --prefix apps/api run seed:demo
```

## Mobile Demo-Flow
1. **Startscreen** öffnen → Events/News/Warnungen prüfen.
2. **Gemeinde-App** → Bürgerbeiträge (z. B. „Suche/Warnung“) öffnen.
3. **Beitrag erstellen** → Pflichtfelder prüfen → Speichern → Eintrag erscheint in der Liste.
4. **Moderation** (falls Staff-Modus) → Beitrag öffnen → bearbeiten/löschen.
5. **Verwaltung** → „Öffnungszeiten & Kontakt“ prüfen → Website-Link öffnen.

## Web-Admin Demo-Flow
1. **Login** → Dashboard öffnen.
2. **Inhalte** → Event/News/Warnung anlegen → speichern → Liste aktualisiert.
3. **Moderation** → Beitrag melden/ausblenden → Status wechselt.
4. **Codes/Residents** → CSV exportieren (Komma/Semikolon).
5. **Health Indicator** → Backend-Status prüfen, bei Fehler Retry.

## Erwartetes Verhalten (Beispiel Moderation)
1. **Citizen Post** melden.
2. **Admin Moderation** → Beitrag „Verbergen“.
3. **Mobile** → Beitrag verschwindet aus der Liste.
4. **Admin Moderation** → Beitrag „Einblenden“ → Beitrag erscheint wieder.
