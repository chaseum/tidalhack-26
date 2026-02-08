import fs from 'fs';
import path from 'path';
import { connectToMongo } from './db/connection';
import { createServer } from './server';

function loadRootEnv() {
  const envPath = path.resolve(__dirname, '../../../.env');
  if (!fs.existsSync(envPath)) return;

  const raw = fs.readFileSync(envPath, 'utf8');
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const eqIndex = trimmed.indexOf('=');
    if (eqIndex === -1) continue;

    const key = trimmed.slice(0, eqIndex).trim();
    const valueRaw = trimmed.slice(eqIndex + 1).trim();
    if (!key || process.env[key] !== undefined) continue;

    const unwrapped =
      (valueRaw.startsWith("'") && valueRaw.endsWith("'")) ||
      (valueRaw.startsWith('"') && valueRaw.endsWith('"'))
        ? valueRaw.slice(1, -1)
        : valueRaw;

    process.env[key] = unwrapped;
  }
}
import { config } from "./env";


async function start() {
  loadRootEnv();
  await connectToMongo();

  const app = createServer();
  app.listen(config.PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`gateway listening on ${config.PORT}`);
  });
}

start().catch((error: unknown) => {
  // eslint-disable-next-line no-console
  console.error('Failed to start gateway:', error);
  process.exitCode = 1;
});
