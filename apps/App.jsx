import React, { useEffect } from 'react';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import HomePage from './Home';
import ChatPage from './Chat';
import PicturesPage from './Pictures';
import SettingsPage from './Settings';
import PetDiaryPage from './PetDiary';
import { AppProvider, useApp } from './AppContext';

function ThemedRoutes() {
  const {
    state: { settings },
  } = useApp();

  useEffect(() => {
    document.body.classList.remove('theme-sunrise', 'theme-forest', 'theme-midnight', 'dyslexia-font');
    document.body.classList.add(`theme-${settings.theme}`);
    if (settings.dyslexiaFont) {
      document.body.classList.add('dyslexia-font');
    }
    document.body.style.setProperty('--font-scale', String(settings.fontScale || 1));
  }, [settings]);

  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/home" element={<HomePage />} />
      <Route path="/chat" element={<ChatPage />} />
      <Route path="/pictures" element={<PicturesPage />} />
      <Route path="/settings" element={<SettingsPage />} />
      <Route path="/petdiary" element={<PetDiaryPage />} />
    </Routes>
  );
}

function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <ThemedRoutes />
      </BrowserRouter>
    </AppProvider>
  );
}

export default App;
