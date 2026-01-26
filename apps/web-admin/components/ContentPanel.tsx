'use client';

import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';
import ErrorNotice from './ErrorNotice';
import LoadingState from './LoadingState';

type EventStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

type MunicipalityEvent = {
  id: string;
  title: string;
  description: string;
  location: string;
  category?: string;
  startAt: string;
  endAt?: string;
  status: EventStatus;
};

type PostStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
type PostType = 'NEWS' | 'WARNING';
type PostPriority = 'LOW' | 'MEDIUM' | 'HIGH';

type MunicipalityPost = {
  id: string;
  type: PostType;
  title: string;
  body: string;
  category?: string;
  priority?: PostPriority;
  publishedAt: string;
  endsAt?: string;
  status: PostStatus;
};

const statusOptions: Array<EventStatus | PostStatus> = [
  'PUBLISHED',
  'DRAFT',
  'ARCHIVED',
];

const toInputDateTime = (value?: string) =>
  value ? new Date(value).toISOString().slice(0, 16) : '';

const toIsoString = (value: string) => new Date(value).toISOString();

const severityToPriority = (severity: string) => {
  switch (severity) {
    case 'CRITICAL':
      return 'HIGH';
    case 'WARN':
      return 'MEDIUM';
    case 'INFO':
    default:
      return 'LOW';
  }
};

const priorityToSeverity = (priority?: PostPriority) => {
  switch (priority) {
    case 'HIGH':
      return 'CRITICAL';
    case 'MEDIUM':
      return 'WARN';
    case 'LOW':
    default:
      return 'INFO';
  }
};

const emptyEventForm = {
  title: '',
  description: '',
  location: '',
  category: '',
  startAt: '',
  endAt: '',
  status: 'PUBLISHED' as EventStatus,
};

const emptyNewsForm = {
  title: '',
  body: '',
  category: '',
  status: 'PUBLISHED' as PostStatus,
};

const emptyWarningForm = {
  title: '',
  body: '',
  category: '',
  severity: 'INFO',
  validUntil: '',
  status: 'PUBLISHED' as PostStatus,
};

export default function ContentPanel() {
  const [activeSection, setActiveSection] = useState<
    'events' | 'news' | 'warnings'
  >('events');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const [events, setEvents] = useState<MunicipalityEvent[]>([]);
  const [eventsSearch, setEventsSearch] = useState('');
  const [eventsStatus, setEventsStatus] = useState<EventStatus>('PUBLISHED');
  const [eventForm, setEventForm] = useState(emptyEventForm);
  const [editingEvent, setEditingEvent] = useState<MunicipalityEvent | null>(
    null,
  );

  const [news, setNews] = useState<MunicipalityPost[]>([]);
  const [newsSearch, setNewsSearch] = useState('');
  const [newsStatus, setNewsStatus] = useState<PostStatus>('PUBLISHED');
  const [newsForm, setNewsForm] = useState(emptyNewsForm);
  const [editingNews, setEditingNews] = useState<MunicipalityPost | null>(null);

  const [warnings, setWarnings] = useState<MunicipalityPost[]>([]);
  const [warningsSearch, setWarningsSearch] = useState('');
  const [warningsStatus, setWarningsStatus] = useState<PostStatus>('PUBLISHED');
  const [warningForm, setWarningForm] = useState(emptyWarningForm);
  const [editingWarning, setEditingWarning] =
    useState<MunicipalityPost | null>(null);

  const loadEvents = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (eventsStatus) {
        params.set('status', eventsStatus);
      }
      const data = await apiFetch<MunicipalityEvent[]>(
        `/api/admin/events${params.toString() ? `?${params.toString()}` : ''}`,
      );
      setEvents(data ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const loadNews = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      params.set('type', 'NEWS');
      if (newsStatus) {
        params.set('status', newsStatus);
      }
      const data = await apiFetch<MunicipalityPost[]>(
        `/api/admin/posts?${params.toString()}`,
      );
      setNews(data ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const loadWarnings = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      params.set('type', 'WARNING');
      if (warningsStatus) {
        params.set('status', warningsStatus);
      }
      const data = await apiFetch<MunicipalityPost[]>(
        `/api/admin/posts?${params.toString()}`,
      );
      setWarnings(data ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (activeSection === 'events') {
      loadEvents();
    }
    if (activeSection === 'news') {
      loadNews();
    }
    if (activeSection === 'warnings') {
      loadWarnings();
    }
  }, [activeSection]);

  const filteredEvents = useMemo(
    () =>
      events.filter((event) =>
        event.title.toLowerCase().includes(eventsSearch.toLowerCase()),
      ),
    [events, eventsSearch],
  );

  const filteredNews = useMemo(
    () =>
      news.filter((item) =>
        item.title.toLowerCase().includes(newsSearch.toLowerCase()),
      ),
    [news, newsSearch],
  );

  const filteredWarnings = useMemo(
    () =>
      warnings.filter((item) =>
        item.title.toLowerCase().includes(warningsSearch.toLowerCase()),
      ),
    [warnings, warningsSearch],
  );

  const saveEvent = async () => {
    setLoading(true);
    setError(null);
    try {
      const payload = {
        title: eventForm.title.trim(),
        description: eventForm.description.trim(),
        location: eventForm.location.trim(),
        category: eventForm.category.trim() || undefined,
        startAt: toIsoString(eventForm.startAt),
        endAt: eventForm.endAt ? toIsoString(eventForm.endAt) : undefined,
        status: eventForm.status,
      };
      if (editingEvent) {
        await apiFetch(`/api/admin/events/${editingEvent.id}`, {
          method: 'PATCH',
          body: JSON.stringify(payload),
        });
      } else {
        await apiFetch('/api/admin/events', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      setEventForm(emptyEventForm);
      setEditingEvent(null);
      await loadEvents();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const deleteEvent = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/events/${id}`, { method: 'DELETE' });
      await loadEvents();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const saveNews = async () => {
    setLoading(true);
    setError(null);
    try {
      const payload = {
        type: 'NEWS' as PostType,
        title: newsForm.title.trim(),
        body: newsForm.body.trim(),
        category: newsForm.category.trim() || undefined,
        status: newsForm.status,
        publishedAt: new Date().toISOString(),
      };
      if (editingNews) {
        await apiFetch(`/api/admin/posts/${editingNews.id}`, {
          method: 'PATCH',
          body: JSON.stringify({
            title: payload.title,
            body: payload.body,
            category: payload.category,
            status: payload.status,
          }),
        });
      } else {
        await apiFetch('/api/admin/posts', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      setNewsForm(emptyNewsForm);
      setEditingNews(null);
      await loadNews();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const deleteNews = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/posts/${id}`, { method: 'DELETE' });
      await loadNews();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const saveWarning = async () => {
    setLoading(true);
    setError(null);
    try {
      const payload = {
        type: 'WARNING' as PostType,
        title: warningForm.title.trim(),
        body: warningForm.body.trim(),
        category: warningForm.category.trim() || undefined,
        status: warningForm.status,
        publishedAt: new Date().toISOString(),
        priority: severityToPriority(warningForm.severity),
        endsAt: warningForm.validUntil
          ? toIsoString(warningForm.validUntil)
          : undefined,
      };
      if (editingWarning) {
        await apiFetch(`/api/admin/posts/${editingWarning.id}`, {
          method: 'PATCH',
          body: JSON.stringify({
            title: payload.title,
            body: payload.body,
            category: payload.category,
            status: payload.status,
            priority: payload.priority,
            endsAt: payload.endsAt,
          }),
        });
      } else {
        await apiFetch('/api/admin/posts', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      setWarningForm(emptyWarningForm);
      setEditingWarning(null);
      await loadWarnings();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const deleteWarning = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      await apiFetch(`/api/admin/posts/${id}`, { method: 'DELETE' });
      await loadWarnings();
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="stack">
      <div className="tabs">
        <button
          type="button"
          className={`tab ${activeSection === 'events' ? 'active' : ''}`}
          onClick={() => setActiveSection('events')}
        >
          Events
        </button>
        <button
          type="button"
          className={`tab ${activeSection === 'news' ? 'active' : ''}`}
          onClick={() => setActiveSection('news')}
        >
          News
        </button>
        <button
          type="button"
          className={`tab ${activeSection === 'warnings' ? 'active' : ''}`}
          onClick={() => setActiveSection('warnings')}
        >
          Warnungen
        </button>
      </div>

      {error && <ErrorNotice error={error} />}
      {loading && <LoadingState />}

      {activeSection === 'events' && (
        <div className="stack">
          <div className="card stack">
            <h3>{editingEvent ? 'Event bearbeiten' : 'Event erstellen'}</h3>
            <div className="row">
              <div className="field">
                <label htmlFor="eventTitle">Titel</label>
                <input
                  id="eventTitle"
                  value={eventForm.title}
                  onChange={(event) =>
                    setEventForm({ ...eventForm, title: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="eventLocation">Ort</label>
                <input
                  id="eventLocation"
                  value={eventForm.location}
                  onChange={(event) =>
                    setEventForm({ ...eventForm, location: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="eventCategory">Kategorie</label>
                <input
                  id="eventCategory"
                  value={eventForm.category}
                  onChange={(event) =>
                    setEventForm({ ...eventForm, category: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="eventStatus">Status</label>
                <select
                  id="eventStatus"
                  value={eventForm.status}
                  onChange={(event) =>
                    setEventForm({
                      ...eventForm,
                      status: event.target.value as EventStatus,
                    })
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="row">
              <div className="field">
                <label htmlFor="eventStart">Start</label>
                <input
                  id="eventStart"
                  type="datetime-local"
                  value={eventForm.startAt}
                  onChange={(event) =>
                    setEventForm({ ...eventForm, startAt: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="eventEnd">Ende (optional)</label>
                <input
                  id="eventEnd"
                  type="datetime-local"
                  value={eventForm.endAt}
                  onChange={(event) =>
                    setEventForm({ ...eventForm, endAt: event.target.value })
                  }
                />
              </div>
              <div className="field" style={{ flex: 1 }}>
                <label htmlFor="eventDescription">Beschreibung</label>
                <textarea
                  id="eventDescription"
                  rows={3}
                  value={eventForm.description}
                  onChange={(event) =>
                    setEventForm({
                      ...eventForm,
                      description: event.target.value,
                    })
                  }
                />
              </div>
            </div>
            <div className="row">
              <button type="button" onClick={saveEvent}>
                {editingEvent ? 'Änderungen speichern' : 'Event anlegen'}
              </button>
              {editingEvent && (
                <button
                  type="button"
                  className="secondary"
                  onClick={() => {
                    setEditingEvent(null);
                    setEventForm(emptyEventForm);
                  }}
                >
                  Abbrechen
                </button>
              )}
            </div>
          </div>

          <div className="card stack">
            <div className="row">
              <div className="field">
                <label htmlFor="eventSearch">Suche</label>
                <input
                  id="eventSearch"
                  value={eventsSearch}
                  onChange={(event) => setEventsSearch(event.target.value)}
                />
              </div>
              <div className="field">
                <label htmlFor="eventFilter">Status</label>
                <select
                  id="eventFilter"
                  value={eventsStatus}
                  onChange={(event) =>
                    setEventsStatus(event.target.value as EventStatus)
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
              <button type="button" onClick={loadEvents}>
                Aktualisieren
              </button>
            </div>
            {filteredEvents.length === 0 ? (
              <p>Keine Events gefunden.</p>
            ) : (
              <div className="table-wrap">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Titel</th>
                      <th>Start</th>
                      <th>Ort</th>
                      <th>Status</th>
                      <th>Aktionen</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredEvents.map((event) => (
                      <tr key={event.id}>
                        <td>{event.title}</td>
                        <td>{new Date(event.startAt).toLocaleString()}</td>
                        <td>{event.location}</td>
                        <td>{event.status}</td>
                        <td className="row">
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => {
                              setEditingEvent(event);
                              setEventForm({
                                title: event.title,
                                description: event.description,
                                location: event.location,
                                category: event.category ?? '',
                                startAt: toInputDateTime(event.startAt),
                                endAt: toInputDateTime(event.endAt),
                                status: event.status,
                              });
                            }}
                          >
                            Bearbeiten
                          </button>
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => deleteEvent(event.id)}
                          >
                            Löschen
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {activeSection === 'news' && (
        <div className="stack">
          <div className="card stack">
            <h3>{editingNews ? 'News bearbeiten' : 'News erstellen'}</h3>
            <div className="row">
              <div className="field">
                <label htmlFor="newsTitle">Titel</label>
                <input
                  id="newsTitle"
                  value={newsForm.title}
                  onChange={(event) =>
                    setNewsForm({ ...newsForm, title: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="newsCategory">Kategorie</label>
                <input
                  id="newsCategory"
                  value={newsForm.category}
                  onChange={(event) =>
                    setNewsForm({ ...newsForm, category: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="newsStatus">Status</label>
                <select
                  id="newsStatus"
                  value={newsForm.status}
                  onChange={(event) =>
                    setNewsForm({
                      ...newsForm,
                      status: event.target.value as PostStatus,
                    })
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="field">
              <label htmlFor="newsBody">Inhalt</label>
              <textarea
                id="newsBody"
                rows={4}
                value={newsForm.body}
                onChange={(event) =>
                  setNewsForm({ ...newsForm, body: event.target.value })
                }
              />
            </div>
            <div className="row">
              <button type="button" onClick={saveNews}>
                {editingNews ? 'Änderungen speichern' : 'News anlegen'}
              </button>
              {editingNews && (
                <button
                  type="button"
                  className="secondary"
                  onClick={() => {
                    setEditingNews(null);
                    setNewsForm(emptyNewsForm);
                  }}
                >
                  Abbrechen
                </button>
              )}
            </div>
          </div>

          <div className="card stack">
            <div className="row">
              <div className="field">
                <label htmlFor="newsSearch">Suche</label>
                <input
                  id="newsSearch"
                  value={newsSearch}
                  onChange={(event) => setNewsSearch(event.target.value)}
                />
              </div>
              <div className="field">
                <label htmlFor="newsFilter">Status</label>
                <select
                  id="newsFilter"
                  value={newsStatus}
                  onChange={(event) =>
                    setNewsStatus(event.target.value as PostStatus)
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
              <button type="button" onClick={loadNews}>
                Aktualisieren
              </button>
            </div>
            {filteredNews.length === 0 ? (
              <p>Keine News gefunden.</p>
            ) : (
              <div className="table-wrap">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Titel</th>
                      <th>Kategorie</th>
                      <th>Status</th>
                      <th>Aktionen</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredNews.map((item) => (
                      <tr key={item.id}>
                        <td>{item.title}</td>
                        <td>{item.category ?? '-'}</td>
                        <td>{item.status}</td>
                        <td className="row">
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => {
                              setEditingNews(item);
                              setNewsForm({
                                title: item.title,
                                body: item.body,
                                category: item.category ?? '',
                                status: item.status,
                              });
                            }}
                          >
                            Bearbeiten
                          </button>
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => deleteNews(item.id)}
                          >
                            Löschen
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {activeSection === 'warnings' && (
        <div className="stack">
          <div className="card stack">
            <h3>{editingWarning ? 'Warnung bearbeiten' : 'Warnung erstellen'}</h3>
            <div className="row">
              <div className="field">
                <label htmlFor="warningTitle">Titel</label>
                <input
                  id="warningTitle"
                  value={warningForm.title}
                  onChange={(event) =>
                    setWarningForm({ ...warningForm, title: event.target.value })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="warningCategory">Kategorie</label>
                <input
                  id="warningCategory"
                  value={warningForm.category}
                  onChange={(event) =>
                    setWarningForm({
                      ...warningForm,
                      category: event.target.value,
                    })
                  }
                />
              </div>
              <div className="field">
                <label htmlFor="warningSeverity">Schweregrad</label>
                <select
                  id="warningSeverity"
                  value={warningForm.severity}
                  onChange={(event) =>
                    setWarningForm({
                      ...warningForm,
                      severity: event.target.value,
                    })
                  }
                >
                  <option value="INFO">Info</option>
                  <option value="WARN">Warnung</option>
                  <option value="CRITICAL">Kritisch</option>
                </select>
              </div>
              <div className="field">
                <label htmlFor="warningStatus">Status</label>
                <select
                  id="warningStatus"
                  value={warningForm.status}
                  onChange={(event) =>
                    setWarningForm({
                      ...warningForm,
                      status: event.target.value as PostStatus,
                    })
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="row">
              <div className="field">
                <label htmlFor="warningValidUntil">Gültig bis (optional)</label>
                <input
                  id="warningValidUntil"
                  type="datetime-local"
                  value={warningForm.validUntil}
                  onChange={(event) =>
                    setWarningForm({
                      ...warningForm,
                      validUntil: event.target.value,
                    })
                  }
                />
              </div>
            </div>
            <div className="field">
              <label htmlFor="warningBody">Inhalt</label>
              <textarea
                id="warningBody"
                rows={4}
                value={warningForm.body}
                onChange={(event) =>
                  setWarningForm({ ...warningForm, body: event.target.value })
                }
              />
            </div>
            <div className="row">
              <button type="button" onClick={saveWarning}>
                {editingWarning ? 'Änderungen speichern' : 'Warnung anlegen'}
              </button>
              {editingWarning && (
                <button
                  type="button"
                  className="secondary"
                  onClick={() => {
                    setEditingWarning(null);
                    setWarningForm(emptyWarningForm);
                  }}
                >
                  Abbrechen
                </button>
              )}
            </div>
          </div>

          <div className="card stack">
            <div className="row">
              <div className="field">
                <label htmlFor="warningSearch">Suche</label>
                <input
                  id="warningSearch"
                  value={warningsSearch}
                  onChange={(event) => setWarningsSearch(event.target.value)}
                />
              </div>
              <div className="field">
                <label htmlFor="warningFilter">Status</label>
                <select
                  id="warningFilter"
                  value={warningsStatus}
                  onChange={(event) =>
                    setWarningsStatus(event.target.value as PostStatus)
                  }
                >
                  {statusOptions.map((status) => (
                    <option key={status} value={status}>
                      {status}
                    </option>
                  ))}
                </select>
              </div>
              <button type="button" onClick={loadWarnings}>
                Aktualisieren
              </button>
            </div>
            {filteredWarnings.length === 0 ? (
              <p>Keine Warnungen gefunden.</p>
            ) : (
              <div className="table-wrap">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Titel</th>
                      <th>Schweregrad</th>
                      <th>Status</th>
                      <th>Aktionen</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredWarnings.map((item) => (
                      <tr key={item.id}>
                        <td>{item.title}</td>
                        <td>{priorityToSeverity(item.priority)}</td>
                        <td>{item.status}</td>
                        <td className="row">
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => {
                              setEditingWarning(item);
                              setWarningForm({
                                title: item.title,
                                body: item.body,
                                category: item.category ?? '',
                                severity: priorityToSeverity(item.priority),
                                validUntil: toInputDateTime(item.endsAt),
                                status: item.status,
                              });
                            }}
                          >
                            Bearbeiten
                          </button>
                          <button
                            type="button"
                            className="secondary"
                            onClick={() => deleteWarning(item.id)}
                          >
                            Löschen
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
