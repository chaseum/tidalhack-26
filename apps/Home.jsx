import React, { useEffect, useMemo, useRef, useState } from 'react';
import BottomNav from './BottomNav';
import cat from './images/cat.png';
import { generatePixelArtFromAnimal } from './geminiPixelArt';
import {
  createTransparentPngFromColor,
  readFileAsBase64,
  toDataUrl,
} from './imagePngTools';
import { useApp } from './AppContext';
import { displayS3JpgByName } from './s3ImageViewer';

function HomePage() {
  const fileInputRef = useRef(null);
  const {
    state: { petProfile, diaryEntries, photos },
  } = useApp();

  const [backgroundHex, setBackgroundHex] = useState(
    import.meta.env.VITE_PIXEL_BG_COLOR || '#66ccff'
  );
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [uploadedFileName, setUploadedFileName] = useState('');
  const [generatedDataUrl, setGeneratedDataUrl] = useState('');
  const [transparentDataUrl, setTransparentDataUrl] = useState('');
  const [s3Status, setS3Status] = useState('Loading S3 image...');

  useEffect(() => {
    const region = import.meta.env.VITE_S3_REGION || 'us-west-2';
    displayS3JpgByName({
      bucket: 'tidal-user-information',
      region,
      Name: 'IMG_0265.jpg',
      target: '#pet-photo',
    })
      .then(() => setS3Status('Loaded from S3'))
      .catch((err) => {
        const message = err instanceof Error ? err.message : 'Failed to load S3 image';
        setS3Status(message);
      });
  }, []);

  const notifications = useMemo(() => {
    const hasRecentBath = diaryEntries.some((entry) => entry.type === 'Bath');
    const hasRecentWalk = diaryEntries.some((entry) => entry.type === 'Walk');
    const hasDental = diaryEntries.some((entry) => entry.type === 'Dental Cleaning');

    return [
      hasRecentWalk
        ? 'Daily movement goal is on track.'
        : 'No walk log yet. Add a walk in Pet Diary.',
      hasRecentBath
        ? 'Bath routine has recent activity.'
        : 'Bath reminder: schedule a wash and coat check.',
      hasDental
        ? 'Dental care logged this cycle.'
        : 'Dental reminder: brush teeth or book a cleaning.',
      photos.length > 0
        ? `${photos.length} wellness photo${photos.length > 1 ? 's' : ''} stored in Pictures.`
        : 'No photos uploaded yet. Start a visual history in Pictures.',
    ];
  }, [diaryEntries, photos.length]);

  const handleCatClick = () => {
    if (!fileInputRef.current) return;
    fileInputRef.current.value = '';
    fileInputRef.current.click();
  };

  const handleFileChange = async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadedFileName(file.name);
    setError('');
    setIsLoading(true);
    setGeneratedDataUrl('');
    setTransparentDataUrl('');

    try {
      const inputImage = await readFileAsBase64(file);
      const generated = await generatePixelArtFromAnimal({
        base64Image: inputImage.base64,
        mimeType: inputImage.mimeType,
        backgroundHex,
      });

      const baseOutput = toDataUrl(generated);
      setGeneratedDataUrl(baseOutput);

      const transparentPng = await createTransparentPngFromColor({
        base64: generated.base64,
        mimeType: generated.mimeType,
        backgroundHex,
      });
      setTransparentDataUrl(transparentPng);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Unexpected error while generating image.';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="page-shell">
      <h1 className="page-header">{petProfile.name}'s Wellness Home</h1>
      <p className="muted">Keep your pet's daily care visible with snapshots, reminders, and health notes.</p>

      <section className="home-layout">
        <article className="card stack">
          <div>
            <span className="notice-pill">Pixel Companion</span>
            <h2 style={{ marginBottom: 8 }}>Upload your pet and generate a pixel portrait</h2>
            <p className="muted">Click the cat image to upload. Portrait generation stays on the frontend flow.</p>
          </div>

          <label htmlFor="bgColorPicker">Pixel background color</label>
          <input
            id="bgColorPicker"
            type="color"
            value={backgroundHex}
            onChange={(event) => setBackgroundHex(event.target.value)}
            style={{ width: 90, height: 42 }}
          />

          <button type="button" className="cat-upload" onClick={handleCatClick}>
            <img src={cat} alt="Upload pet photo by clicking this cat" />
          </button>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            style={{ display: 'none' }}
          />

          {uploadedFileName && <p className="small muted">Selected file: {uploadedFileName}</p>}
          {isLoading && <p>Generating pixel art...</p>}
          {error && <p style={{ color: 'var(--danger)', fontWeight: 700 }}>{error}</p>}

          {generatedDataUrl && (
            <div>
              <h3>Generated Pixel Art</h3>
              <img className="pixel-preview" src={generatedDataUrl} alt="Generated pixel art" />
            </div>
          )}

          {transparentDataUrl && (
            <div className="stack">
              <h3 style={{ marginBottom: 0 }}>Transparent PNG</h3>
              <img className="pixel-preview" src={transparentDataUrl} alt="Transparent PNG output" />
              <a className="button" href={transparentDataUrl} download="pet-pixel-transparent.png">
                Download PNG
              </a>
            </div>
          )}
        </article>

        <article className="card stack">
          <div>
            <span className="notice-pill">Wellness Pulse</span>
            <h2 style={{ marginBottom: 8 }}>Today's care feed</h2>
            <p className="muted">
              {petProfile.name} ({petProfile.species}, {petProfile.age})
            </p>
          </div>

          <ul className="notice-list">
            {notifications.map((text) => (
              <li key={text}>{text}</li>
            ))}
          </ul>

          <div className="card" style={{ padding: 12, marginTop: 6 }}>
            <h3 style={{ marginBottom: 8 }}>Flavor Text</h3>
            <p className="muted" style={{ margin: 0 }}>
              "Consistency beats intensity. Small daily care rituals protect long-term health."
            </p>
          </div>

          <div className="card" style={{ padding: 12 }}>
            <h3 style={{ marginBottom: 8 }}>S3 Image Preview</h3>
            <img id="pet-photo" className="pixel-preview" alt="S3 pet preview" />
            <p className="small muted" style={{ marginBottom: 0 }}>
              {s3Status}
            </p>
          </div>
        </article>
      </section>

      <BottomNav />
    </main>
  );
}

export default HomePage;
