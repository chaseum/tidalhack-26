import { connectToMongo, disconnectMongo, getMongoUri } from '../db/connection';
import { allModels } from '../db/models';

async function main() {
  await connectToMongo();

  for (const dbModel of allModels) {
    await dbModel.syncIndexes();
  }

  // eslint-disable-next-line no-console
  console.log(`MongoDB initialized with indexes at ${getMongoUri()}`);

  await disconnectMongo();
}

main().catch((error: unknown) => {
  // eslint-disable-next-line no-console
  console.error('Failed to initialize MongoDB:', error);
  process.exitCode = 1;
});
