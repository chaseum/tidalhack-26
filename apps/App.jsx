import React, { useEffect } from 'react';
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router-dom';
import HomePage from './Home';
import ChatPage from './Chat';
import PicturesPage from './Pictures';
import SettingsPage from './Settings';
import PetDiaryPage from './PetDiary';
import LoginPage from './Login';
import RegisterPage from './Register';
import { AppProvider, useApp } from './AppContext';

function hasAuthToken() {
  const token = localStorage.getItem('petapp_auth_token');
  return Boolean(token && token.trim().length > 0);
}

function ProtectedRoute() {
  if (!hasAuthToken()) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}

function PublicOnlyRoute() {
  if (hasAuthToken()) {
    return <Navigate to="/home" replace />;
  }
  return <Outlet />;
}

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
      <Route element={<PublicOnlyRoute />}>
        <Route path="/" element={<LoginPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
      </Route>

      <Route element={<ProtectedRoute />}>
        <Route path="/home" element={<HomePage />} />
        <Route path="/chat" element={<ChatPage />} />
        <Route path="/pictures" element={<PicturesPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/petdiary" element={<PetDiaryPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
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
