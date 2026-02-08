const LIST_MODELS_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

export async function listGeminiModels() {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('Missing VITE_GEMINI_API_KEY. Set it in apps/.env and restart the dev server');
  }

  const response = await fetch(LIST_MODELS_ENDPOINT, {
    method: 'GET',
    headers: {
      'x-goog-api-key': apiKey,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`ListModels failed (${response.status}): ${body}`);
  }

  const data = await response.json();
  return data.models || [];
}

export async function listGenerateContentModels() {
  const models = await listGeminiModels();

  return models
    .filter((model) => (model.supportedGenerationMethods || []).includes('generateContent'))
    .map((model) => ({
      name: model.name,
      displayName: model.displayName,
      supportedGenerationMethods: model.supportedGenerationMethods || [],
      inputTokenLimit: model.inputTokenLimit,
      outputTokenLimit: model.outputTokenLimit,
    }));
}

// Optional helper for quick browser-console debugging:
// import { printGenerateContentModels } from './listGeminiModels';
// await printGenerateContentModels();
export async function printGenerateContentModels() {
  const models = await listGenerateContentModels();
  console.table(models);
  return models;
}
