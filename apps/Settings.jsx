import React from 'react';
import { useNavigate } from 'react-router-dom';
import BottomNav from './BottomNav';
import { useApp } from './AppContext';

function SettingsPage() {
  const navigate = useNavigate();
  const {
    state: { settings, petProfile },
    actions,
  } = useApp();

  const handleLogout = () => {
    localStorage.removeItem('petapp_auth_token');
    localStorage.removeItem('petapp_auth_user');
    navigate('/login', { replace: true });
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">Settings</h1>
      <p className="muted">Accessibility and personalization options are frontend-only and saved in your browser.</p>

      <section className="grid-two">
        <article className="card">
          <h2>Accessibility</h2>

          <div className="settings-row">
            <label htmlFor="themeSelect">Theme</label>
            <select
              id="themeSelect"
              value={settings.theme}
              onChange={(event) => actions.updateSettings({ theme: event.target.value })}
            >
              <option value="sunrise">Sunrise</option>
              <option value="forest">Forest</option>
              <option value="midnight">Midnight</option>
            </select>
          </div>

          <div className="settings-row">
            <label htmlFor="fontScale">Font size scale ({settings.fontScale.toFixed(2)}x)</label>
            <input
              id="fontScale"
              type="range"
              min="0.9"
              max="1.3"
              step="0.05"
              value={settings.fontScale}
              onChange={(event) =>
                actions.updateSettings({ fontScale: Number.parseFloat(event.target.value) })
              }
            />
          </div>

          <div className="settings-row">
            <label htmlFor="dyslexiaFont">Dyslexia-friendly font</label>
            <select
              id="dyslexiaFont"
              value={settings.dyslexiaFont ? 'on' : 'off'}
              onChange={(event) =>
                actions.updateSettings({ dyslexiaFont: event.target.value === 'on' })
              }
            >
              <option value="off">Off</option>
              <option value="on">On</option>
            </select>
          </div>
        </article>

        <article className="card stack">
          <h2>Pet profile</h2>

          <div>
            <label htmlFor="petName">Name</label>
            <input
              id="petName"
              value={petProfile.name}
              onChange={(event) => actions.updatePetProfile({ name: event.target.value })}
            />
          </div>

          <div>
            <label htmlFor="petSpecies">Species</label>
            <input
              id="petSpecies"
              value={petProfile.species}
              onChange={(event) => actions.updatePetProfile({ species: event.target.value })}
            />
          </div>

          <div>
            <label htmlFor="petAge">Age</label>
            <input
              id="petAge"
              value={petProfile.age}
              onChange={(event) => actions.updatePetProfile({ age: event.target.value })}
            />
          </div>

          <button type="button" className="button ghost" onClick={() => actions.clearAllData()}>
            Reset Local App Data
          </button>

          <button type="button" className="button" onClick={handleLogout}>
            Logout
          </button>
        </article>
      </section>

      <BottomNav />
    </main>
  );
}

export default SettingsPage;
