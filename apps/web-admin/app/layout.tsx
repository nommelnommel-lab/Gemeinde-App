import type { ReactNode } from 'react';
import './globals.css';

export const metadata = {
  title: 'Gemeinde Admin',
  description: 'Admin Panel für Bewohner und Aktivierungscodes',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="de">
      <body>
        <div className="app-shell">
          <header className="app-header">
            <div>
              <h1>Gemeinde Admin</h1>
              <p>Bewohnerverwaltung &amp; Aktivierungscodes</p>
            </div>
          </header>
          <main className="app-content">{children}</main>
        </div>
      </body>
    </html>
  );
}
