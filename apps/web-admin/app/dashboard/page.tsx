'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ResidentsPanel from '../../components/ResidentsPanel';
import ImportPanel from '../../components/ImportPanel';
import CodesPanel from '../../components/CodesPanel';
import RolesPanel from '../../components/RolesPanel';
import { clearSession, loadSession } from '../../lib/storage';

const tabs = [
  { id: 'residents', label: 'Bewohner' },
  { id: 'import', label: 'Import' },
  { id: 'codes', label: 'Codes' },
  { id: 'roles', label: 'Rollen' },
] as const;

type TabId = (typeof tabs)[number]['id'];

export default function DashboardPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TabId>('residents');

  useEffect(() => {
    const session = loadSession();
    if (!session) {
      router.replace('/login');
    }
  }, [router]);

  const handleLogout = () => {
    clearSession();
    router.replace('/login');
  };

  return (
    <div className="stack">
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
    </div>
  );
}
