import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';
import { readFileAsBase64 } from './imagePngTools';
import { assessPhoto, fetchPhotos, uploadPhoto } from './apiClient';

function getMonthGrid(referenceDate) {
  const year = referenceDate.getFullYear();
  const month = referenceDate.getMonth();
  const first = new Date(year, month, 1);
  const offset = (first.getDay() + 6) % 7;
  const days = new Date(year, month + 1, 0).getDate();
  const cells = [];

  for (let i = 0; i < offset; i += 1) {
    cells.push(null);
  }

  for (let day = 1; day <= days; day += 1) {
    const iso = new Date(year, month, day).toISOString().slice(0, 10);
    cells.push(iso);
  }

  while (cells.length % 7 !== 0) {
    cells.push(null);
  }

  return cells;
}

function normalizeSpecies(speciesRaw) {
  const normalized = String(speciesRaw || '')
    .trim()
    .toLowerCase();
  if (normalized === 'dog' || normalized === 'cat') {
    return normalized;
  }
  return undefined;
}

function PicturesPage() {
  const navigate = useNavigate();
  const {
    state: { petProfile, latestAssess },
    actions,
  } = useApp();

  const [petId, setPetId] = useState(latestAssess?.petId || '');
  const [photos, setPhotos] = useState([]);
  const [caption, setCaption] = useState('');
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [error, setError] = useState('');
  const [monthCursor, setMonthCursor] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [assessing, setAssessing] = useState(false);
  const [assessResult, setAssessResult] = useState(latestAssess || null);

  const loadPhotos = async () => {
    setLoading(true);
    setError('');
    try {
      const payload = await fetchPhotos({ petId: petId || undefined });
      setPhotos(Array.isArray(payload.photos) ? payload.photos : []);

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
      const message = err instanceof Error ? err.message : 'Could not load photos.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPhotos();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const photoCountByDate = useMemo(() => {
    return photos.reduce((acc, photo) => {
      const d = photo.date;
      acc[d] = (acc[d] || 0) + 1;
      return acc;
    }, {});
  }, [photos]);

  const calendarCells = useMemo(() => getMonthGrid(monthCursor), [monthCursor]);

  const handleUpload = async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setError('');
    setUploading(true);
    setAssessing(false);

    try {
      if (!['image/jpeg', 'image/jpg'].includes(file.type.toLowerCase())) {
        throw new Error('Only JPG images are allowed for upload and assess.');
      }

      const raw = await readFileAsBase64(file);
      const payload = await uploadPhoto({
        petId: petId || undefined,
        fileName: file.name,
        mimeType: raw.mimeType,
        base64Data: raw.base64,
        caption: caption.trim(),
        date,
      });

      const resolvedPetId = payload.pet?.id || petId || '';

      if (resolvedPetId) {
        setPetId(resolvedPetId);
      }

      if (payload.pet?.name || payload.pet?.species) {
        actions.updatePetProfile({
          name: payload.pet?.name || petProfile.name,
          species: payload.pet?.species || petProfile.species,
        });
      }

      if (payload.photo) {
        setPhotos((prev) => [payload.photo, ...prev]);
      } else {
        await loadPhotos();
      }

      setCaption('');
      setUploading(false);

      setAssessing(true);
      const assessed = await assessPhoto({
        file,
        petId: resolvedPetId || undefined,
        species: normalizeSpecies(payload.pet?.species || petProfile.species),
      });

      const nextAssess = {
        ...assessed,
        petId: resolvedPetId,
        photoId: payload.photo?.id || null,
        photoUrl: payload.photo?.objectUrl || '',
        fileName: file.name,
        assessedAt: new Date().toISOString(),
      };

      setAssessResult(nextAssess);
      actions.setLatestAssess(nextAssess);
      actions.setLatestPlan(null);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not process image.';
      setError(message);
    } finally {
      setUploading(false);
      setAssessing(false);
      event.target.value = '';
    }
  };

  const monthLabel = monthCursor.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
  });

  return (
    <main className="page-shell">
      <h1 className="page-header">Scan</h1>
      <p className="muted">Upload a JPG, run AI body condition assessment, then continue into plan and coaching.</p>

      <section className="grid-two">
        <article className="card stack">
          <h2>Add photo</h2>
          <div>
            <label htmlFor="photoDate">Photo date</label>
            <input
              id="photoDate"
              type="date"
              value={date}
              onChange={(event) => setDate(event.target.value)}
            />
          </div>

          <div>
            <label htmlFor="photoCaption">Caption</label>
            <input
              id="photoCaption"
              placeholder="Coat condition, appetite, mood..."
              value={caption}
              onChange={(event) => setCaption(event.target.value)}
            />
          </div>

          <div>
            <label htmlFor="photoUpload">Upload JPG image</label>
            <input id="photoUpload" type="file" accept=".jpg,.jpeg,image/jpeg" onChange={handleUpload} />
          </div>

          {error && <p style={{ color: 'var(--danger)', fontWeight: 700 }}>{error}</p>}
          {loading && <p className="muted">Loading photos...</p>}
          {uploading && <p className="muted">Uploading to S3...</p>}
          {assessing && <p className="muted">Assessing image...</p>}

          <h3 style={{ marginBottom: 6 }}>Photo calendar</h3>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, alignItems: 'center' }}>
            <button
              type="button"
              className="button ghost"
              onClick={() =>
                setMonthCursor((prev) => new Date(prev.getFullYear(), prev.getMonth() - 1, 1))
              }
            >
              Prev
            </button>
            <strong>{monthLabel}</strong>
            <button
              type="button"
              className="button ghost"
              onClick={() =>
                setMonthCursor((prev) => new Date(prev.getFullYear(), prev.getMonth() + 1, 1))
              }
            >
              Next
            </button>
          </div>

          <div className="calendar">
            {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => (
              <strong key={day} className="small muted" style={{ textAlign: 'center' }}>
                {day}
              </strong>
            ))}
            {calendarCells.map((iso, index) => {
              if (!iso) {
                return <div key={`blank-${index}`} className="calendar-cell" style={{ opacity: 0.3 }} />;
              }

              const day = Number(iso.slice(-2));
              const count = photoCountByDate[iso] || 0;
              return (
                <div key={iso} className="calendar-cell">
                  <div>{day}</div>
                  {count > 0 && <span className="calendar-dot">{count} photo</span>}
                </div>
              );
            })}
          </div>
        </article>

        <article className="card stack">
          <h2>Assessment Result</h2>
          {!assessResult && <p className="muted">Upload a photo to run /assess and view the results card.</p>}

          {assessResult && (
            <>
              <div className="card" style={{ padding: 12 }}>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Bucket: <strong>{assessResult.bucket}</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Confidence: <strong>{Math.round((assessResult.confidence || 0) * 100)}%</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Species: <strong>{assessResult.species}</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 0 }}>Mask available: {assessResult.mask?.available ? 'Yes' : 'No'}</p>
              </div>

              <div className="card" style={{ padding: 12 }}>
                <h3 style={{ marginBottom: 8 }}>Top Breed Probabilities</h3>
                <ul className="notice-list" style={{ marginBottom: 0 }}>
                  {(assessResult.breed_top3 || []).map((item) => (
                    <li key={item.breed}>
                      {item.breed}: {Math.round((item.p || 0) * 100)}%
                    </li>
                  ))}
                </ul>
              </div>

              <div className="card" style={{ padding: 12 }}>
                <h3 style={{ marginBottom: 8 }}>Notes</h3>
                <p style={{ margin: 0 }}>{assessResult.notes}</p>
              </div>

              {assessResult.ratios && (
                <div className="card" style={{ padding: 12 }}>
                  <h3 style={{ marginBottom: 8 }}>Ratios</h3>
                  <p style={{ marginTop: 0, marginBottom: 6 }}>
                    Waist to chest: {Number(assessResult.ratios.waist_to_chest).toFixed(3)}
                  </p>
                  <p style={{ marginTop: 0, marginBottom: 6 }}>
                    Belly tuck: {Number(assessResult.ratios.belly_tuck).toFixed(3)}
                  </p>
                  <p style={{ margin: 0 }}>
                    Length (px): {Math.round(Number(assessResult.ratios.length_px) || 0)}
                  </p>
                </div>
              )}

              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                <button type="button" className="button" onClick={() => navigate('/plan')}>
                  Continue to Plan
                </button>
                <button
                  type="button"
                  className="button secondary"
                  onClick={() =>
                    navigate('/chat', {
                      state: {
                        prefill: `My pet was assessed as ${assessResult.bucket} with ${Math.round(
                          (assessResult.confidence || 0) * 100
                        )}% confidence. Coach me on next steps today.`,
                      },
                    })
                  }
                >
                  Ask Coach
                </button>
              </div>
            </>
          )}

          <h2 style={{ marginBottom: 0 }}>Gallery</h2>
          {!loading && photos.length === 0 && <p className="muted">No photos yet. Upload your first JPG.</p>}
          <div className="photo-grid">
            {photos.map((photo) => (
              <figure key={photo.id} className="photo-tile" style={{ margin: 0 }}>
                <img src={photo.objectUrl} alt={photo.caption || photo.fileName || 'Pet upload'} />
                <figcaption style={{ padding: 8 }}>
                  <div className="small muted">{photo.date}</div>
                  <div>{photo.caption || photo.fileName || 'No caption'}</div>
                  <div className="small muted">{photo.fileName}</div>
                </figcaption>
              </figure>
            ))}
          </div>
        </article>
      </section>

      <BottomNav />
    </main>
  );
}

export default PicturesPage;
