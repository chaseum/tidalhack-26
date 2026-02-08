import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';

const STORAGE_KEY = 'pet-wellness-app-state-v1';

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

const defaultState = {
  petProfile: {
    name: 'Mochi',
    species: 'Cat',
    age: '3 years',
  },
  diaryEntries: [
    {
      id: 'd1',
      type: 'Walk',
      date: todayIso(),
      notes: '20 minute neighborhood walk, energy was good.',
    },
    {
      id: 'd2',
      type: 'Dental Cleaning',
      date: todayIso(),
      notes: 'Brushed teeth with poultry toothpaste, no irritation.',
    },
  ],
  photos: [],
  chatMessages: [
    {
      id: 'm1',
      role: 'assistant',
      text: 'Hi. I can help track your pet wellness routine and add suggested actions to the diary.',
      createdAt: new Date().toISOString(),
    },
  ],
  latestAssess: null,
  latestPlan: null,
  settings: {
    theme: 'sunrise',
    fontScale: 1,
    dyslexiaFont: false,
  },
};

const AppContext = createContext(null);

function readState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultState;
    const parsed = JSON.parse(raw);
    return {
      ...defaultState,
      ...parsed,
      petProfile: { ...defaultState.petProfile, ...(parsed.petProfile || {}) },
      settings: { ...defaultState.settings, ...(parsed.settings || {}) },
      diaryEntries: Array.isArray(parsed.diaryEntries) ? parsed.diaryEntries : defaultState.diaryEntries,
      photos: Array.isArray(parsed.photos) ? parsed.photos : [],
      chatMessages: Array.isArray(parsed.chatMessages) ? parsed.chatMessages : defaultState.chatMessages,
      latestAssess:
        parsed.latestAssess && typeof parsed.latestAssess === 'object' ? parsed.latestAssess : null,
      latestPlan: parsed.latestPlan && typeof parsed.latestPlan === 'object' ? parsed.latestPlan : null,
    };
  } catch (_err) {
    return defaultState;
  }
}

export function AppProvider({ children }) {
  const [state, setState] = useState(defaultState);

  useEffect(() => {
    setState(readState());
  }, []);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  const actions = useMemo(
    () => ({
      updatePetProfile: (patch) => {
        setState((prev) => ({
          ...prev,
          petProfile: {
            ...prev.petProfile,
            ...patch,
          },
        }));
      },
      addDiaryEntry: ({ type, date, notes }) => {
        const entry = {
          id: `d-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
          type,
          date: date || todayIso(),
          notes,
        };
        setState((prev) => ({
          ...prev,
          diaryEntries: [entry, ...prev.diaryEntries],
        }));
      },
      addPhoto: ({ dataUrl, caption, date }) => {
        const photo = {
          id: `p-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
          dataUrl,
          caption: caption || '',
          date: date || todayIso(),
          createdAt: new Date().toISOString(),
        };
        setState((prev) => ({
          ...prev,
          photos: [photo, ...prev.photos],
        }));
      },
      addChatMessage: ({ role, text }) => {
        const message = {
          id: `m-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
          role,
          text,
          createdAt: new Date().toISOString(),
        };
        setState((prev) => ({
          ...prev,
          chatMessages: [...prev.chatMessages, message],
        }));
      },
      setLatestAssess: (assess) => {
        setState((prev) => ({
          ...prev,
          latestAssess: assess || null,
        }));
      },
      setLatestPlan: (plan) => {
        setState((prev) => ({
          ...prev,
          latestPlan: plan || null,
        }));
      },
      updateSettings: (patch) => {
        setState((prev) => ({
          ...prev,
          settings: {
            ...prev.settings,
            ...patch,
          },
        }));
      },
      clearAllData: () => {
        setState(defaultState);
      },
    }),
    []
  );

  const value = useMemo(() => ({ state, actions }), [state, actions]);

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const value = useContext(AppContext);
  if (!value) {
    throw new Error('useApp must be used inside AppProvider');
  }
  return value;
}
