function hexToRgb(hex) {
  const cleanHex = hex.replace('#', '').trim();
  const normalized = cleanHex.length === 3
    ? cleanHex.split('').map((char) => char + char).join('')
    : cleanHex;

  if (!/^[0-9a-fA-F]{6}$/.test(normalized)) {
    throw new Error('Background color must be a valid hex color, e.g. #66ccff');
  }

  return {
    r: parseInt(normalized.slice(0, 2), 16),
    g: parseInt(normalized.slice(2, 4), 16),
    b: parseInt(normalized.slice(4, 6), 16),
  };
}

export function toDataUrl({ base64, mimeType }) {
  return `data:${mimeType};base64,${base64}`;
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('Could not load generated image.'));
    img.src = src;
  });
}

export async function createTransparentPngFromColor({ base64, mimeType, backgroundHex, tolerance = 26 }) {
  const img = await loadImage(toDataUrl({ base64, mimeType }));
  const canvas = document.createElement('canvas');
  canvas.width = img.width;
  canvas.height = img.height;

  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(img, 0, 0);

  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const pixels = imageData.data;
  const target = hexToRgb(backgroundHex);

  for (let i = 0; i < pixels.length; i += 4) {
    const r = pixels[i];
    const g = pixels[i + 1];
    const b = pixels[i + 2];

    const isMatch =
      Math.abs(r - target.r) <= tolerance &&
      Math.abs(g - target.g) <= tolerance &&
      Math.abs(b - target.b) <= tolerance;

    if (isMatch) {
      pixels[i + 3] = 0;
    }
  }

  ctx.putImageData(imageData, 0, 0);
  return canvas.toDataURL('image/png');
}

export function readFileAsBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      if (typeof result !== 'string') {
        reject(new Error('Could not read uploaded file.'));
        return;
      }

      const commaIndex = result.indexOf(',');
      const base64 = result.slice(commaIndex + 1);
      resolve({
        base64,
        mimeType: file.type || 'image/png',
      });
    };
    reader.onerror = () => reject(new Error('Could not read uploaded file.'));
    reader.readAsDataURL(file);
  });
}
