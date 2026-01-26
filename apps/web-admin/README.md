# Web-Admin

## Lokales Starten

```bash
npm --prefix apps/web-admin install
npm --prefix apps/web-admin run dev -p 3001
```

## Umgebungsvariablen

Der Web-Admin nutzt keine zwingenden Umgebungsvariablen. Die API-Verbindung
(Base URL, Tenant, Site Key, Admin Key) wird beim Login eingegeben.

## Bekannte Ports

- **3001**: Next.js Dev-Server (`apps/web-admin`)

## Manuelle Smoke-Checks

1. Bewohner anlegen (Tab **Bewohner**).
2. Aktivierungscode generieren und CSV exportieren (Tab **Codes**).
3. Offizielle News erstellen (Tab **Inhalte** → **News**).
4. Citizen-Post in der mobilen App erstellen, melden und im Tab **Moderation**
   prüfen, anschließend ausblenden und wieder einblenden.
