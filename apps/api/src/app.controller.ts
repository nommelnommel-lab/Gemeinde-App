import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  getHealth() {
    return { status: 'ok' };
  }

  @Get('events')
  getEvents() {
    return [
      {
        id: 'event-1',
        title: 'Gemeindefest',
        description: 'Ein gemeinsamer Nachmittag mit Musik und Buffet.',
        date: '2024-09-14T14:00:00.000Z',
        location: 'Gemeindezentrum',
      },
      {
        id: 'event-2',
        title: 'Jugendabend',
        description: 'Spiele, Snacks und Austausch für Jugendliche.',
        date: '2024-09-20T17:30:00.000Z',
        location: 'Jugendraum',
      },
      {
        id: 'event-3',
        title: 'Flohmarkt',
        description: 'Stöbern, verkaufen und Kaffee trinken.',
        date: '2024-10-05T09:00:00.000Z',
        location: 'Kirchplatz',
      },
      {
        id: 'event-4',
        title: 'Chorprobe',
        description: 'Offene Probe für alle, die mitsingen möchten.',
        date: '2024-10-11T18:00:00.000Z',
        location: 'Proberaum',
      },
      {
        id: 'event-5',
        title: 'Vortrag: Nachhaltig leben',
        description: 'Impulse und Diskussion rund um Nachhaltigkeit.',
        date: '2024-10-18T18:30:00.000Z',
        location: 'Gemeindesaal',
      },
    ];
  }
}
