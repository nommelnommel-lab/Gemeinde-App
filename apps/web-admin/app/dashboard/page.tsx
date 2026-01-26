'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ResidentsPanel from '../../components/ResidentsPanel';
import ImportPanel from '../../components/ImportPanel';
import CodesPanel from '../../components/CodesPanel';
import TouristCodesPanel from '../../components/TouristCodesPanel';
import RolesPanel from '../../components/RolesPanel';
import ContentPanel from '../../components/ContentPanel';
import ModerationPanel from '../../components/ModerationPanel';
import TourismPanel from '../../components/TourismPanel';
import { apiFetch, fetchHealthStatus } from '../../lib/api';
import { clearSession, loadSession } from '../../lib/storage';

const tabs = [
  { id: 'residents', label: 'Bewohner' },
  { id: 'import', label: 'Import' },
  { id: 'codes', label: 'Codes' },
  { id: 'tourist-codes', label: 'Tourist-Codes' },
  { id: 'roles', label: 'Rollen' },
  { id: 'content', label: 'Inhalte' },
  { id: 'tourism', label: 'Tourismus' },
  { id: 'moderation', label: 'Moderation' },
] as const;

type TabId = (typeof tabs)[number]['id'];

export default function DashboardPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TabId>('residents');
  const [healthStatus, setHealthStatus] = useState<{
    state: 'ok' | 'down' | 'unknown';
    status?: number;
    message?: string;
  }>({ state: 'unknown' });
  const [healthChecking, setHealthChecking] = useState(false);
  const [demoResetStatus, setDemoResetStatus] = useState<{
    tone: 'success' | 'error';
    message: string;
  } | null>(null);
  const [demoResetting, setDemoResetting] = useState(false);

  const isDemoTenant =
    process.env.NEXT_PUBLIC_TENANT === 'hilders-demo' ||
    process.env.NEXT_PUBLIC_DEFAULT_TENANT === 'hilders-demo';

  useEffect(() => {
    const session = loadSession();
    if (!session) {
      router.replace('/login');
    }
  }, [router]);

  const checkHealth = async (force = false) => {
    const session = loadSession();
    if (!session) {
      return;
    }
    setHealthChecking(true);
    try {
      const status = await fetchHealthStatus({ force });
      setHealthStatus({
        state: status.state,
        status: status.status,
        message: status.message,
      });
    } catch (error) {
      setHealthStatus({
        state: 'down',
        status: 0,
        message:
          error instanceof Error
            ? error.message
            : 'Backend nicht erreichbar',
      });
    } finally {
      setHealthChecking(false);
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  useEffect(() => {
    if (!demoResetStatus) {
      return undefined;
    }
    const timeout = window.setTimeout(() => {
      setDemoResetStatus(null);
    }, 4000);
    return () => window.clearTimeout(timeout);
  }, [demoResetStatus]);

  const handleLogout = () => {
    clearSession();
    router.replace('/login');
  };

  const handleDemoReset = async () => {
    setDemoResetting(true);
    setDemoResetStatus(null);
    try {
      await apiFetch('/api/admin/demo/reset', { method: 'POST' });
      setDemoResetStatus({
        tone: 'success',
        message: 'Demo-Daten wurden neu befüllt.',
      });
    } catch (error) {
      setDemoResetStatus({
        tone: 'error',
        message:
          error instanceof Error
            ? error.message
            : 'Demo-Reset fehlgeschlagen.',
      });
    } finally {
      setDemoResetting(false);
    }
  };

  const healthLabel =
    healthStatus.state === 'ok'
      ? 'API OK'
      : healthStatus.state === 'down'
        ? 'API Down'
        : 'API Prüfen…';

  return (
    <div className="stack">
      {isDemoTenant && (
        <div className="card stack" style={{ gap: '12px' }}>
          <div>
            <strong>Demo</strong>
            <p style={{ margin: '4px 0 0', color: 'var(--color-muted)' }}>
              Setzt die Demo-Datenbank zurück und erstellt Beispieldaten neu.
            </p>
          </div>
          {demoResetStatus && (
            <div className={`notice ${demoResetStatus.tone}`}>
              {demoResetStatus.message}
            </div>
          )}
          <div className="row" style={{ gap: '12px' }}>
            <button
              type="button"
              className="secondary"
              onClick={handleDemoReset}
              disabled={demoResetting}
            >
              {demoResetting
                ? 'Demo-Daten werden neu befüllt…'
                : 'Demo-Daten neu befüllen'}
            </button>
          </div>
        </div>
      )}
      {healthStatus.state === 'down' && (
        <div className="notice error">
          <div>
            Backend nicht erreichbar. Bitte API Base URL prüfen. (HTTP{' '}
            {healthStatus.status ?? '–'}:{' '}
            {healthStatus.message ?? 'Unbekannter Fehler'})
          </div>
          <div className="row" style={{ marginTop: '0.5rem' }}>
            <button
              type="button"
              onClick={() => checkHealth(true)}
              disabled={healthChecking}
            >
              {healthChecking ? 'Prüfe…' : 'Erneut prüfen'}
            </button>
          </div>
        </div>
      )}
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <div className="tabs">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              className={`tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <div className="row" style={{ gap: '0.75rem', alignItems: 'center' }}>
          <span
            className={`badge health-pill ${healthStatus.state === 'ok' ? 'success' : healthStatus.state === 'down' ? 'error' : ''}`}
            title="API Health"
          >
            {healthLabel}
          </span>
          <button type="button" className="ghost" onClick={handleLogout}>
            Logout
          </button>
        </div>
      </div>
      {activeTab === 'residents' && <ResidentsPanel />}
      {activeTab === 'import' && <ImportPanel />}
      {activeTab === 'codes' && <CodesPanel />}
      {activeTab === 'tourist-codes' && <TouristCodesPanel />}
      {activeTab === 'roles' && <RolesPanel />}
      {activeTab === 'content' && <ContentPanel />}
      {activeTab === 'tourism' && <TourismPanel />}
      {activeTab === 'moderation' && <ModerationPanel />}
    </div>
  );
}
