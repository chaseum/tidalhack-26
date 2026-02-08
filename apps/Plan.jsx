import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';
import { createPlan, fetchPhotos } from './apiClient';

const buckets = ['UNDERWEIGHT', 'IDEAL', 'OVERWEIGHT', 'OBESE', 'UNKNOWN'];
const activities = ['LOW', 'MODERATE', 'HIGH'];
const goals = ['LOSE', 'MAINTAIN', 'GAIN'];

function normalizeSpecies(speciesRaw) {
  const normalized = String(speciesRaw || '')
    .trim()
    .toLowerCase();
  if (normalized === 'dog' || normalized === 'cat') {
    return normalized;
  }
  return 'dog';
}

function defaultGoalForBucket(bucket) {
  if (bucket === 'OVERWEIGHT' || bucket === 'OBESE') {
    return 'LOSE';
  }
  if (bucket === 'UNDERWEIGHT') {
    return 'GAIN';
  }
  return 'MAINTAIN';
}

function PlanPage() {
  const navigate = useNavigate();
  const {
    state: { petProfile, latestAssess, latestPlan },
    actions,
  } = useApp();

  const [petId, setPetId] = useState(latestAssess?.petId || latestPlan?.pet_id || '');
  const [species, setSpecies] = useState(
    normalizeSpecies(latestAssess?.species || latestPlan?.species || petProfile.species)
  );
  const [weightKg, setWeightKg] = useState('');
  const [bucket, setBucket] = useState(latestAssess?.bucket || latestPlan?.bucket || 'IDEAL');
  const [activity, setActivity] = useState(latestPlan?.activity || 'MODERATE');
  const [goal, setGoal] = useState(
    latestPlan?.goal || defaultGoalForBucket(latestAssess?.bucket || latestPlan?.bucket || 'IDEAL')
  );
  const [foodMode, setFoodMode] = useState('per_g');
  const [kcalPerG, setKcalPerG] = useState(latestPlan?.kcal_per_g ? String(latestPlan.kcal_per_g) : '');
  const [kcalPerCup, setKcalPerCup] = useState('');
  const [gramsPerCup, setGramsPerCup] = useState('');

  const [loadingPet, setLoadingPet] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [planResult, setPlanResult] = useState(latestPlan || null);

  useEffect(() => {
    if (petId) {
      return;
    }

    let cancelled = false;
    const resolvePet = async () => {
      setLoadingPet(true);
      try {
        const payload = await fetchPhotos();
        if (!cancelled && payload.pet?.id) {
          setPetId(payload.pet.id);
        }
      } catch (err) {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : 'Could not resolve pet ID.';
          setError(message);
        }
      } finally {
        if (!cancelled) {
          setLoadingPet(false);
        }
      }
    };

    resolvePet();
    return () => {
      cancelled = true;
    };
  }, [petId]);

  const coachPrefill = useMemo(() => {
    if (!planResult) {
      return '';
    }

    return `My feeding plan is ${planResult.daily_calories} kcal/day and ${planResult.grams_per_day} g/day. Build a practical 7-day coaching checklist for meals, activity, and monitoring.`;
  }, [planResult]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');

    if (!petId) {
      setError('Pet ID is required before planning. Upload or fetch a pet photo first.');
      return;
    }

    if (!weightKg || Number(weightKg) <= 0) {
      setError('Weight must be greater than 0 kg.');
      return;
    }

    if (foodMode === 'per_g' && (!kcalPerG || Number(kcalPerG) <= 0)) {
      setError('kcal per gram must be greater than 0.');
      return;
    }

    if (
      foodMode === 'per_cup' &&
      (!kcalPerCup || Number(kcalPerCup) <= 0 || !gramsPerCup || Number(gramsPerCup) <= 0)
    ) {
      setError('For cup mode, provide both kcal per cup and grams per cup.');
      return;
    }

    setSubmitting(true);
    try {
      const planned = await createPlan({
        petId,
        species,
        weightKg,
        bucket,
        activity,
        goal,
        kcalPerG: foodMode === 'per_g' ? kcalPerG : undefined,
        kcalPerCup: foodMode === 'per_cup' ? kcalPerCup : undefined,
        gramsPerCup: foodMode === 'per_cup' ? gramsPerCup : undefined,
      });

      const nextPlan = {
        ...planned,
        createdAt: new Date().toISOString(),
      };

      setPlanResult(nextPlan);
      actions.setLatestPlan(nextPlan);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not create plan.';
      setError(message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Plan</h1>
      <p className="muted">Generate a concrete feeding plan from your pet profile and latest assessment.</p>

      <section className="grid-two">
        <article className="card stack">
          <h2>Plan inputs</h2>

          {latestAssess && (
            <div className="card" style={{ padding: 12 }}>
              <h3 style={{ marginBottom: 8 }}>Latest Assess Snapshot</h3>
              <p style={{ marginTop: 0, marginBottom: 6 }}>
                Bucket: <strong>{latestAssess.bucket}</strong>
              </p>
              <p style={{ marginTop: 0, marginBottom: 6 }}>
                Confidence: <strong>{Math.round((latestAssess.confidence || 0) * 100)}%</strong>
              </p>
              <p style={{ margin: 0 }}>Species: {latestAssess.species}</p>
            </div>
          )}

          <form className="stack" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="planPetId">Pet ID</label>
              <input
                id="planPetId"
                value={petId}
                onChange={(event) => setPetId(event.target.value)}
                placeholder="pet_123"
              />
              {loadingPet && <p className="small muted">Resolving pet ID...</p>}
            </div>

            <div>
              <label htmlFor="planSpecies">Species</label>
              <select id="planSpecies" value={species} onChange={(event) => setSpecies(event.target.value)}>
                <option value="dog">dog</option>
                <option value="cat">cat</option>
              </select>
            </div>

            <div>
              <label htmlFor="planWeight">Weight (kg)</label>
              <input
                id="planWeight"
                type="number"
                min="0"
                step="0.1"
                value={weightKg}
                onChange={(event) => setWeightKg(event.target.value)}
                placeholder="10.5"
              />
            </div>

            <div>
              <label htmlFor="planBucket">BCS bucket</label>
              <select id="planBucket" value={bucket} onChange={(event) => setBucket(event.target.value)}>
                {buckets.map((item) => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="planActivity">Activity</label>
              <select id="planActivity" value={activity} onChange={(event) => setActivity(event.target.value)}>
                {activities.map((item) => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="planGoal">Goal</label>
              <select id="planGoal" value={goal} onChange={(event) => setGoal(event.target.value)}>
                {goals.map((item) => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="foodMode">Food calories mode</label>
              <select id="foodMode" value={foodMode} onChange={(event) => setFoodMode(event.target.value)}>
                <option value="per_g">kcal per gram</option>
                <option value="per_cup">kcal per cup + grams per cup</option>
              </select>
            </div>

            {foodMode === 'per_g' && (
              <div>
                <label htmlFor="kcalPerG">kcal per g</label>
                <input
                  id="kcalPerG"
                  type="number"
                  min="0"
                  step="0.01"
                  value={kcalPerG}
                  onChange={(event) => setKcalPerG(event.target.value)}
                  placeholder="3.5"
                />
              </div>
            )}

            {foodMode === 'per_cup' && (
              <>
                <div>
                  <label htmlFor="kcalPerCup">kcal per cup</label>
                  <input
                    id="kcalPerCup"
                    type="number"
                    min="0"
                    step="0.1"
                    value={kcalPerCup}
                    onChange={(event) => setKcalPerCup(event.target.value)}
                    placeholder="370"
                  />
                </div>
                <div>
                  <label htmlFor="gramsPerCup">grams per cup</label>
                  <input
                    id="gramsPerCup"
                    type="number"
                    min="0"
                    step="0.1"
                    value={gramsPerCup}
                    onChange={(event) => setGramsPerCup(event.target.value)}
                    placeholder="104"
                  />
                </div>
              </>
            )}

            {error && <p style={{ color: 'var(--danger)', fontWeight: 700, margin: 0 }}>{error}</p>}

            <button className="button" type="submit" disabled={submitting}>
              {submitting ? 'Generating plan...' : 'Generate Plan'}
            </button>
          </form>
        </article>

        <article className="card stack">
          <h2>Plan result</h2>
          {!planResult && <p className="muted">Submit the form to call /plan and view the generated feeding plan.</p>}

          {planResult && (
            <>
              <div className="card" style={{ padding: 12 }}>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Daily calories: <strong>{planResult.daily_calories} kcal</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Daily food amount: <strong>{planResult.grams_per_day} g</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  RER: <strong>{Number(planResult.rer).toFixed(2)}</strong>
                </p>
                <p style={{ marginTop: 0, marginBottom: 8 }}>
                  Multiplier: <strong>{Number(planResult.multiplier).toFixed(2)}</strong>
                </p>
                <p style={{ margin: 0 }}>{planResult.disclaimer}</p>
              </div>

              <button
                type="button"
                className="button secondary"
                onClick={() => navigate('/chat', { state: { prefill: coachPrefill } })}
              >
                Continue to Coach
              </button>
            </>
          )}
        </article>
      </section>

      <BottomNav />
    </main>
  );
}

export default PlanPage;
