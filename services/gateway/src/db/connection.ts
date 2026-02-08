import mongoose from 'mongoose';

const DEFAULT_DB_NAME = 'pet_wellness';

export function getMongoUri(): string {
  return process.env.MONGODB_URI ?? `mongodb://127.0.0.1:27017/${DEFAULT_DB_NAME}`;
}

export async function connectToMongo(): Promise<typeof mongoose> {
  const uri = getMongoUri();
  return mongoose.connect(uri, {
    autoIndex: true,
  });
}

export async function disconnectMongo(): Promise<void> {
  await mongoose.disconnect();
}
