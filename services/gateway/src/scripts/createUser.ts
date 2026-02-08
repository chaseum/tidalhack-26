import { connectToMongo, disconnectMongo } from '../db/connection';
import { UserModel } from '../db/models';
import { hashPassword } from '../db/password';

function readArg(name: string): string | undefined {
  const prefix = `--${name}=`;
  const match = process.argv.find((value) => value.startsWith(prefix));
  return match ? match.slice(prefix.length) : undefined;
}

async function main() {
  const email = readArg('email');
  const password = readArg('password');
  const displayName = readArg('name');

  if (!email || !password) {
    throw new Error('Usage: node dist/scripts/createUser.js --email=user@example.com --password=supersecret [--name=Owner]');
  }

  await connectToMongo();

  const existing = await UserModel.findOne({ email: email.toLowerCase().trim() });
  if (existing) {
    throw new Error(`User already exists for ${email}`);
  }

  const passwordHash = await hashPassword(password);

  const user = await UserModel.create({
    email,
    passwordHash,
    displayName,
    isEmailVerified: false,
  });

  // eslint-disable-next-line no-console
  console.log(`Created user ${user.email} with id ${user._id.toString()}`);

  await disconnectMongo();
}

main().catch(async (error: unknown) => {
  // eslint-disable-next-line no-console
  console.error('Failed to create user:', error);
  await disconnectMongo().catch(() => undefined);
  process.exitCode = 1;
});
