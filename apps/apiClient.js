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

function getErrorReason(payload, fallback) {
  if (payload && typeof payload === 'object' && 'error' in payload) {
    const errorValue = payload.error;
    if (typeof errorValue === 'string' && errorValue.trim()) {
      return errorValue;
    }
    if (errorValue && typeof errorValue === 'object') {
      if (typeof errorValue.message === 'string' && errorValue.message.trim()) {
        return errorValue.message;
      }
      if (typeof errorValue.code === 'string' && errorValue.code.trim()) {
        return errorValue.code;
      }
    }
  }
  return fallback;
}

async function request(path, options) {
  const authHeaders = getAuthHeaders();
  const mergedHeaders = {
    ...authHeaders,
    ...(options?.headers || {}),
  };

  if (
    !(options?.body instanceof FormData) &&
    !Object.prototype.hasOwnProperty.call(mergedHeaders, 'Content-Type')
  ) {
    mergedHeaders['Content-Type'] = 'application/json';
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: mergedHeaders,
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
    const reason = getErrorReason(payload, response.statusText);
    throw new Error(String(reason || `Request failed (${response.status})`));
  }

  return payload;
}

async function requestJson(path, options) {
  return request(path, options);
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

export async function assessPhoto({ file, petId, species, breedHint }) {
  const formData = new FormData();
  formData.append('image', file, file?.name || 'upload.jpg');

  const requestPayload = {};
  if (petId) {
    requestPayload.pet_id = petId;
  }
  if (species) {
    requestPayload.species = species;
  }
  if (breedHint) {
    requestPayload.breed_hint = breedHint;
  }
  formData.append('request', JSON.stringify(requestPayload));

  return request('/assess', {
    method: 'POST',
    body: formData,
  });
}

export async function createPlan({
  petId,
  species,
  weightKg,
  bucket,
  activity,
  goal,
  kcalPerG,
  kcalPerCup,
  gramsPerCup,
}) {
  const food = {};
  if (kcalPerG !== undefined && kcalPerG !== null && kcalPerG !== '') {
    food.kcal_per_g = Number(kcalPerG);
  } else if (
    kcalPerCup !== undefined &&
    kcalPerCup !== null &&
    kcalPerCup !== '' &&
    gramsPerCup !== undefined &&
    gramsPerCup !== null &&
    gramsPerCup !== ''
  ) {
    food.kcal_per_cup = Number(kcalPerCup);
    food.grams_per_cup = Number(gramsPerCup);
  }

  return requestJson('/plan', {
    method: 'POST',
    body: JSON.stringify({
      pet_id: petId,
      species,
      weight_kg: Number(weightKg),
      bucket,
      activity,
      goal,
      food,
    }),
  });
}

export async function sendChatMessage({ message, sessionId }) {
  return requestJson('/chat', {
    method: 'POST',
    body: JSON.stringify({
      message,
      session_id: sessionId || undefined,
    }),
  });
}
