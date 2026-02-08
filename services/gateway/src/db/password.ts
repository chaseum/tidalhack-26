import bcrypt from 'bcryptjs';

const DEFAULT_SALT_ROUNDS = 12;

export async function hashPassword(plainPassword: string): Promise<string> {
  if (plainPassword.length < 8) {
    throw new Error('Password must be at least 8 characters long');
  }
  return bcrypt.hash(plainPassword, DEFAULT_SALT_ROUNDS);
}

export async function verifyPassword(plainPassword: string, passwordHash: string): Promise<boolean> {
  return bcrypt.compare(plainPassword, passwordHash);
}
