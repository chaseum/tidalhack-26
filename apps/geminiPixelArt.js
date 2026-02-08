const DEFAULT_MODEL = 'gemini-2.5-flash-image';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseRetryDelayMs(errorBody) {
  const retryInfo = errorBody?.error?.details?.find(
    (detail) => detail?.['@type'] === 'type.googleapis.com/google.rpc.RetryInfo'
  );

  const rawDelay = retryInfo?.retryDelay;
  if (!rawDelay || typeof rawDelay !== 'string') return 0;

  const seconds = Number.parseFloat(rawDelay.replace('s', ''));
  if (Number.isNaN(seconds) || seconds <= 0) return 0;
  return Math.ceil(seconds * 1000);
}

function toFriendlyQuotaError({ statusCode, errorBody }) {
  const retryMs = parseRetryDelayMs(errorBody);
  const retrySeconds = retryMs > 0 ? Math.ceil(retryMs / 1000) : null;
  const details =
    errorBody?.error?.message ||
    'Gemini quota/rate-limit exceeded. Check billing and enabled quota for your model.';

  const retryText = retrySeconds
    ? ` Retry in about ${retrySeconds}s.`
    : '';

  return new Error(
    `Gemini request failed (${statusCode}): ${details} ` +
      `Update quota/billing in Google AI Studio for ${DEFAULT_MODEL}.` +
      retryText
  );
}

function extractInlineImage(response) {
  const candidates = response?.candidates || [];
  for (const candidate of candidates) {
    const parts = candidate?.content?.parts || [];
    for (const part of parts) {
      const inlineData = part?.inlineData || part?.inline_data;
      if (inlineData?.data) {
        return {
          base64: inlineData.data,
          mimeType: inlineData.mimeType || inlineData.mime_type || 'image/png',
        };
      }
    }
  }
  return null;
}

export async function generatePixelArtFromAnimal({ base64Image, mimeType, backgroundHex }) {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('Missing VITE_GEMINI_API_KEY. Set it in apps/.env and restart the dev server');
  }

  const bg = backgroundHex || '#66ccff';
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${DEFAULT_MODEL}:generateContent`;

  const requestBody = {
    contents: [
      {
        parts: [
          {
            text:
              `Create a clean pixel art sprite based on this animal photo. ` +
              `Keep the animal recognizable and centered. ` +
              `Use a flat, solid background color exactly ${bg}. ` +
              `Use crisp pixel edges, no gradients, and no text.`,
          },
          {
            inlineData: {
              mimeType,
              data: base64Image,
            },
          },
        ],
      },
    ],
    generationConfig: {
      responseModalities: ['IMAGE'],
      imageConfig: {
        aspectRatio: '1:1',
      },
    },
  };

  let apiResponse;
  while (true) {
    apiResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify(requestBody),
    });

    if (apiResponse.status !== 429) {
      break;
    }

    let quotaBody = {};
    try {
      quotaBody = await apiResponse.json();
    } catch (_err) {
      quotaBody = {};
    }

    const retryMs = parseRetryDelayMs(quotaBody);
    await sleep(retryMs > 0 ? retryMs : 5000);
  }

  if (!apiResponse.ok) {
    if (apiResponse.status === 404) {
      const failure = await apiResponse.text();
      throw new Error(
        `Gemini request failed (404): ${failure} ` +
          `This app is locked to ${DEFAULT_MODEL}. Verify this model is available for your key/project.`
      );
    }

    const failure = await apiResponse.text();
    throw new Error(`Gemini request failed (${apiResponse.status}): ${failure}`);
  }

  const response = await apiResponse.json();

  const imagePart = extractInlineImage(response);
  if (!imagePart) {
    throw new Error('Gemini did not return an image. Try another upload or prompt.');
  }

  return imagePart;
}
