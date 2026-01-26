'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type UserRole = 'USER' | 'STAFF' | 'ADMIN';

type UserSummary = {
  id: string;
  email: string;
  displayName?: string | null;
  residentId: string;
  role: UserRole;
  createdAt: string;
};

type UsersResponse = {
  users: UserSummary[];
};

const roleOptions: UserRole[] = ['USER', 'STAFF', 'ADMIN'];

export default function RolesPanel() {
  const [query, setQuery] = useState('');
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [selectedUserId, setSelectedUserId] = useState('');
  const [emailInput, setEmailInput] = useState('');
  const [role, setRole] = useState<UserRole>('USER');
  const [message, setMessage] = useState<string | null>(null);

  const loadUsers = async (value = query) => {
    setLoading(true);
    setError(null);
    try {
      const search = value.trim();
      const data = await apiFetch<UsersResponse>(
        `/api/admin/users${search ? `?q=${encodeURIComponent(search)}` : ''}`,
      );
      setUsers(data?.users ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateRole = async () => {
    setMessage(null);
    setError(null);
    try {
      const payload = {
        role,
        ...(selectedUserId
          ? { userId: selectedUserId }
          : { email: emailInput }),
      };
      await apiFetch('/api/admin/users/role', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      setMessage('Rolle wurde erfolgreich aktualisiert.');
      await loadUsers();
    } catch (err) {
      setError(err);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  return (
    <div className="stack">
      <div className="notice">
        Rollen steuern Staff-Mode und Rechte in der App.
      </div>
      <div className="row">
        <div className="field">
          <label htmlFor="userSearch">Suche (E-Mail oder ID)</label>
          <input
            id="userSearch"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
        <button type="button" onClick={() => loadUsers(query)}>
          Suchen
        </button>
      </div>

      <div className="card">
        <h3>Rolle setzen</h3>
        <p className="small">
          Hinweis: Rollen bestimmen den Zugriff auf den Staff-Modus in der
          mobilen App.
        </p>
        <div className="row">
          <div className="field">
            <label htmlFor="userId">User ID</label>
            <select
              id="userId"
              value={selectedUserId}
              onChange={(event) => {
                setSelectedUserId(event.target.value);
                if (event.target.value) {
                  setEmailInput('');
                }
              }}
            >
              <option value="">-- auswählen --</option>
              {users.map((user) => (
                <option key={user.id} value={user.id}>
                  {user.email}
                  {user.displayName ? ` (${user.displayName})` : ''} ({user.role})
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="email">E-Mail (alternativ)</label>
            <input
              id="email"
              value={emailInput}
              onChange={(event) => {
                setEmailInput(event.target.value);
                if (event.target.value) {
                  setSelectedUserId('');
                }
              }}
              placeholder="user@example.com"
            />
          </div>
          <div className="field">
            <label htmlFor="role">Rolle</label>
            <select
              id="role"
              value={role}
              onChange={(event) => setRole(event.target.value as UserRole)}
            >
              {roleOptions.map((value) => (
                <option key={value} value={value}>
                  {value}
                </option>
              ))}
            </select>
          </div>
        </div>
        <button
          type="button"
          onClick={handleUpdateRole}
          disabled={!selectedUserId && !emailInput.trim()}
        >
          Rolle speichern
        </button>
        {message && <div className="notice success">{message}</div>}
      </div>

      {error && <ErrorNotice error={error} />}
      {loading ? (
        <LoadingState />
      ) : (
        <div className="card">
          <h3>Benutzer</h3>
          {users.length === 0 ? (
            <p>Keine Benutzer gefunden.</p>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>E-Mail</th>
                  <th>User ID</th>
                  <th>Rolle</th>
                  <th>Resident</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id}>
                    <td>{user.email}</td>
                    <td>{user.id}</td>
                    <td>{user.role}</td>
                    <td>{user.residentId}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
