/**
 * Simple browser-side S3 JPG loader for public objects.
 *
 * Usage:
 *   import { displayS3JpgByName } from './s3ImageViewer';
 *   displayS3JpgByName({
 *     bucket: 'my-public-bucket',
 *     region: 'us-east-1',
 *     Name: 'fluffy',
 *     target: '#pet-photo'
 *   });
 */

function buildS3Url(bucket, region, Name) {
  const normalizedName = Name.toLowerCase().endsWith('.jpg')
    ? Name
    : `${Name}.jpg`;

  // Keep path separators but encode each segment.
  const encodedKey = normalizedName
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');

  // us-east-1 works with this format as well.
  return `https://${bucket}.s3.${region}.amazonaws.com/${encodedKey}`;
}

export async function displayS3JpgByName({ bucket, region, Name, target }) {
  if (!bucket || !region || !Name || !target) {
    throw new Error('bucket, region, Name, and target are required');
  }

  const img = typeof target === 'string' ? document.querySelector(target) : target;
  if (!img || img.tagName !== 'IMG') {
    throw new Error('target must be an <img> element or selector pointing to one');
  }

  const url = buildS3Url(bucket, region, Name);
  img.alt = Name;

  return new Promise((resolve, reject) => {
    img.onload = () => {
      resolve({ url, contentType: 'image/jpeg' });
    };
    img.onerror = () => {
      reject(
        new Error(
          'Failed to load image from S3. Verify object path, public read permission, and bucket policy.'
        )
      );
    };
    img.src = url;
  });
}
