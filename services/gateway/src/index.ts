import { loadRootEnv } from './config/loadRootEnv';
import { connectToMongo } from './db/connection';
import { createServer } from './server';
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
