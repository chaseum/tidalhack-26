import React, { useEffect, useMemo, useState } from 'react';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';
import { createDiaryEntry, fetchDiaryEntries } from './apiClient';

const entryTypes = [
  'Walk',
  'Bath',
  'Dental Cleaning',
  'Vet Visit',
  'Medication',
  'Nutrition',
  'Grooming',
  'Symptom',
  'Behavior',
  'Vaccination',
  'Other',
];

function PetDiaryPage() {
  const {
    state: { petProfile },
    actions,
  } = useApp();

  const [petId, setPetId] = useState('');
  const [type, setType] = useState('Walk');
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [notes, setNotes] = useState('');
  const [query, setQuery] = useState('');
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const loadDiary = async () => {
    setLoading(true);
    setError('');
    try {
      const payload = await fetchDiaryEntries({ petId: petId || undefined });
      const fetchedEntries = Array.isArray(payload.entries) ? payload.entries : [];
      setEntries(fetchedEntries);

      if (payload.pet?.id) {
        setPetId(payload.pet.id);
      }
      if (payload.pet?.name || payload.pet?.species) {
        actions.updatePetProfile({
          name: payload.pet?.name || petProfile.name,
          species: payload.pet?.species || petProfile.species,
        });
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not load diary entries.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDiary();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filteredEntries = useMemo(() => {
    if (!query.trim()) return entries;
    const term = query.toLowerCase();
    return entries.filter(
      (entry) =>
        String(entry.type || '')?.toLowerCase().includes(term) ||
        String(entry.notes || '')?.toLowerCase().includes(term) ||
        String(entry.date || '').includes(term)
    );
  }, [entries, query]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!notes.trim()) return;

    setSubmitting(true);
    setError('');
    try {
      const payload = await createDiaryEntry({
        petId: petId || undefined,
        type,
        date,
        notes: notes.trim(),
      });

      if (payload.pet?.id) {
        setPetId(payload.pet.id);
      }

      if (payload.entry) {
        setEntries((prev) => [payload.entry, ...prev]);
      } else {
        await loadDiary();
      }

      setNotes('');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not save diary entry.';
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Pet Diary</h1>
      <p className="muted">
        Track every wellness event for {petProfile.name}: walks, baths, dental, vet, and more.
      </p>

      <section className="grid-two">
        <article className="card">
          <h2>Add wellness entry</h2>
          <form className="stack" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="entryType">Type</label>
              <select id="entryType" value={type} onChange={(event) => setType(event.target.value)}>
                {entryTypes.map((entryType) => (
                  <option key={entryType} value={entryType}>
                    {entryType}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="entryDate">Date</label>
              <input
                id="entryDate"
                type="date"
                value={date}
                onChange={(event) => setDate(event.target.value)}
              />
            </div>

            <div>
              <label htmlFor="entryNotes">Notes</label>
              <textarea
                id="entryNotes"
                rows={4}
                placeholder="What happened, how they behaved, any concerns..."
                value={notes}
                onChange={(event) => setNotes(event.target.value)}
              />
            </div>

            <button className="button" type="submit" disabled={submitting}>
              {submitting ? 'Saving...' : 'Save Entry'}
            </button>
          </form>
        </article>

        <article className="card">
          <h2>History timeline</h2>
          <div className="stack" style={{ marginBottom: 10 }}>
            <label htmlFor="searchDiary">Search diary</label>
            <input
              id="searchDiary"
              placeholder="Search by type, note, or date"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </div>

          {error && <p style={{ color: 'var(--danger)', marginTop: 0 }}>{error}</p>}
          {loading && <p className="muted">Loading diary...</p>}

          <div className="diary-list">
            {!loading && filteredEntries.length === 0 && <p className="muted">No matching entries yet.</p>}
            {filteredEntries.map((entry) => (
              <div className="diary-item" key={entry.id}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10 }}>
                  <strong>{entry.type}</strong>
                  <span className="small muted">{entry.date}</span>
                </div>
                <p style={{ marginBottom: 0 }}>{entry.notes}</p>
              </div>
            ))}
          </div>
        </article>
      </section>

      <BottomNav />
    </main>
  );
}

export default PetDiaryPage;
