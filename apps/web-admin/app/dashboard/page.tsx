'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ResidentsPanel from '../../components/ResidentsPanel';
import ImportPanel from '../../components/ImportPanel';
import CodesPanel from '../../components/CodesPanel';
import RolesPanel from '../../components/RolesPanel';
import ContentPanel from '../../components/ContentPanel';
import ModerationPanel from '../../components/ModerationPanel';
import { buildAdminHeaders } from '../../lib/api';
import { clearSession, loadSession } from '../../lib/storage';

const tabs = [
  { id: 'residents', label: 'Bewohner' },
  { id: 'import', label: 'Import' },
  { id: 'codes', label: 'Codes' },
  { id: 'roles', label: 'Rollen' },
  { id: 'content', label: 'Inhalte' },
  { id: 'moderation', label: 'Moderation' },
] as const;

type TabId = (typeof tabs)[number]['id'];

export default function DashboardPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TabId>('residents');
  const [healthStatus, setHealthStatus] = useState<'ok' | 'down' | 'unknown'>(
    'unknown',
  );

  useEffect(() => {
    const session = loadSession();
    if (!session) {
      router.replace('/login');
    }
  }, [router]);

  useEffect(() => {
    const checkHealth = async () => {
      const session = loadSession();
      if (!session) {
        return;
      }
      try {
        const response = await fetch(
          new URL('/health', session.apiBaseUrl).toString(),
          {
            headers: buildAdminHeaders(session),
          },
        );
        setHealthStatus(response.ok ? 'ok' : 'down');
      } catch {
        setHealthStatus('down');
      }
    };
    checkHealth();
  }, []);

  const handleLogout = () => {
    clearSession();
    router.replace('/login');
  };

  return (
    <div className="stack">
      {healthStatus === 'down' && (
        <div className="notice error">
          Backend nicht erreichbar. Bitte API Base URL prüfen.
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
        <button type="button" className="ghost" onClick={handleLogout}>
          Logout
        </button>
      </div>
      {activeTab === 'residents' && <ResidentsPanel />}
      {activeTab === 'import' && <ImportPanel />}
      {activeTab === 'codes' && <CodesPanel />}
      {activeTab === 'roles' && <RolesPanel />}
      {activeTab === 'content' && <ContentPanel />}
      {activeTab === 'moderation' && <ModerationPanel />}
    </div>
  );
}
