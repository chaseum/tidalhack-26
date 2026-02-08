const API_BASE_URL = import.meta.env.VITE_GATEWAY_URL || 'http://localhost:8000';

function getAuthHeaders() {
  const headers = {};

  const token = localStorage.getItem('petapp_auth_token');
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const rawUser = localStorage.getItem('petapp_auth_user');
  if (rawUser) {
    try {
      const user = JSON.parse(rawUser);
      if (user?.id) {
        headers['X-User-Id'] = user.id;
      }
    } catch (_err) {
      // Ignore malformed local user storage.
    }
  }

  return headers;
}

async function requestJson(path, options) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders(),
      ...(options?.headers || {}),
    },
    ...options,
  });

  const text = await response.text();
  let payload = {};
  try {
    payload = text ? JSON.parse(text) : {};
  } catch (_err) {
    payload = { raw: text };
  }

  if (!response.ok) {
    const reason =
      payload && typeof payload === 'object' && 'error' in payload
        ? payload.error
        : response.statusText;
    throw new Error(String(reason || `Request failed (${response.status})`));
  }

  return payload;
}

export async function registerUser({ email, password, displayName }) {
  return requestJson('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ email, password, displayName }),
  });
}

export async function loginUser({ email, password }) {
  return requestJson('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
}

export async function fetchDiaryEntries({ petId } = {}) {
  const query = petId ? `?petId=${encodeURIComponent(petId)}` : '';
  return requestJson(`/diary${query}`, {
    method: 'GET',
  });
}

export async function createDiaryEntry({ petId, type, date, notes, durationMinutes, tags }) {
  return requestJson('/diary', {
    method: 'POST',
    body: JSON.stringify({ petId, type, date, notes, durationMinutes, tags }),
  });
}

export async function fetchPhotos({ petId } = {}) {
  const query = petId ? `?petId=${encodeURIComponent(petId)}` : '';
  return requestJson(`/photos${query}`, { method: 'GET' });
}

export async function uploadPhoto({ petId, fileName, mimeType, base64Data, caption, date }) {
  return requestJson('/photos/upload', {
    method: 'POST',
    body: JSON.stringify({
      petId,
      fileName,
      mimeType,
      base64Data,
      caption,
      date,
    }),
  });
}
