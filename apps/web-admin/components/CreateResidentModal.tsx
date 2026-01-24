'use client';

import { FormEvent, useState } from 'react';
import ErrorNotice from './ErrorNotice';
import { apiFetch } from '../lib/api';

type CreateResidentModalProps = {
  onClose: () => void;
  onCreated: () => void;
};

type ResidentPayload = {
  firstName: string;
  lastName: string;
  postalCode: string;
  houseNumber: string;
};

export default function CreateResidentModal({
  onClose,
  onCreated,
}: CreateResidentModalProps) {
  const [payload, setPayload] = useState<ResidentPayload>({
    firstName: '',
    lastName: '',
    postalCode: '',
    houseNumber: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await apiFetch('/api/admin/residents', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      onCreated();
      onClose();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <div className="modal">
        <h3>Bewohner anlegen</h3>
        <ErrorNotice error={error} />
        <form className="stack" onSubmit={onSubmit}>
          <div className="row">
            <div className="field">
              <label htmlFor="firstName">Vorname</label>
              <input
                id="firstName"
                value={payload.firstName}
                onChange={(event) =>
                  setPayload({ ...payload, firstName: event.target.value })
                }
                required
              />
            </div>
            <div className="field">
              <label htmlFor="lastName">Nachname</label>
              <input
                id="lastName"
                value={payload.lastName}
                onChange={(event) =>
                  setPayload({ ...payload, lastName: event.target.value })
                }
                required
              />
            </div>
          </div>
          <div className="row">
            <div className="field">
              <label htmlFor="postalCode">PLZ</label>
              <input
                id="postalCode"
                value={payload.postalCode}
                onChange={(event) =>
                  setPayload({ ...payload, postalCode: event.target.value })
                }
                required
              />
            </div>
            <div className="field">
              <label htmlFor="houseNumber">Hausnummer</label>
              <input
                id="houseNumber"
                value={payload.houseNumber}
                onChange={(event) =>
                  setPayload({ ...payload, houseNumber: event.target.value })
                }
                required
              />
            </div>
          </div>
          <div className="row">
            <button type="submit" disabled={loading}>
              {loading ? 'Speichern...' : 'Speichern'}
            </button>
            <button
              type="button"
              className="secondary"
              onClick={onClose}
            >
              Abbrechen
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
