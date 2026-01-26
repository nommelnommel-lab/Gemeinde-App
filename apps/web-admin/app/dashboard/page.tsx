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
import { fetchHealthStatus } from '../../lib/api';
import { clearSession, loadSession } from '../../lib/storage';

const tabs = [
  { id: 'residents', label: 'Bewohner' },
  { id: 'import', label: 'Import' },
  { id: 'codes', label: 'Codes' },
  { id: 'tourist-codes', label: 'Tourist-Codes' },
  { id: 'roles', label: 'Rollen' },
  { id: 'content', label: 'Inhalte' },
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

  const handleLogout = () => {
    clearSession();
    router.replace('/login');
  };

  const healthLabel =
    healthStatus.state === 'ok'
      ? 'API OK'
      : healthStatus.state === 'down'
        ? 'API Down'
        : 'API Prüfen…';

  return (
    <div className="stack">
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
      {activeTab === 'moderation' && <ModerationPanel />}
    </div>
  );
}
