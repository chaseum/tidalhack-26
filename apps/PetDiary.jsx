import React, { useMemo, useState } from 'react';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';

const entryTypes = [
  'Walk',
  'Bath',
  'Dental Cleaning',
  'Vet Visit',
  'Medication',
  'Nutrition',
  'Grooming',
  'Mood Check',
  'Other',
];

function PetDiaryPage() {
  const {
    state: { petProfile, diaryEntries },
    actions,
  } = useApp();

  const [type, setType] = useState('Walk');
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [notes, setNotes] = useState('');
  const [query, setQuery] = useState('');

  const filteredEntries = useMemo(() => {
    if (!query.trim()) return diaryEntries;
    const term = query.toLowerCase();
    return diaryEntries.filter(
      (entry) =>
        entry.type.toLowerCase().includes(term) ||
        entry.notes.toLowerCase().includes(term) ||
        entry.date.includes(term)
    );
  }, [diaryEntries, query]);

  const handleSubmit = (event) => {
    event.preventDefault();
    if (!notes.trim()) return;

    actions.addDiaryEntry({
      type,
      date,
      notes: notes.trim(),
    });

    setNotes('');
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Pet Diary</h1>
      <p className="muted">Track every wellness event for {petProfile.name}: walks, baths, dental, vet, and more.</p>

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

            <button className="button" type="submit">
              Save Entry
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

          <div className="diary-list">
            {filteredEntries.length === 0 && <p className="muted">No matching entries yet.</p>}
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
