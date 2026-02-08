import { randomUUID } from 'crypto';
import { Router } from 'express';
import { z } from 'zod';
import { AuthSessionModel, UserModel } from '../db/models';
import { hashPassword, verifyPassword } from '../db/password';
import { validateBody } from '../middleware/validate';

export const authRouter = Router();

const registerBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1).max(120).optional(),
});

const loginBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

function sanitizeUser(user: { _id: unknown; email: string; displayName?: string | null }) {
  return {
    id: String(user._id),
    email: user.email,
    displayName: user.displayName ?? '',
  };
}

authRouter.post('/register', validateBody(registerBodySchema), async (req, res) => {
  try {
    const email = req.body.email.toLowerCase().trim();
    const existing = await UserModel.findOne({ email }).lean();

    if (existing) {
      return res.status(409).json({ error: 'EmailAlreadyInUse' });
    }

    const passwordHash = await hashPassword(req.body.password);

    const user = await UserModel.create({
      email,
      passwordHash,
      displayName: req.body.displayName,
      isEmailVerified: false,
      lastLoginAt: new Date(),
      loginCount: 1,
    });

    const token = randomUUID();
    const refreshTokenHash = await hashPassword(token);

    await AuthSessionModel.create({
      userId: user._id,
      refreshTokenHash,
      userAgent: req.header('user-agent') ?? '',
      ipAddress: req.ip,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7),
    });

    return res.status(201).json({
      user: sanitizeUser(user),
      token,
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Register failed:', error);
    return res.status(500).json({ error: 'RegisterFailed' });
  }
});

authRouter.post('/login', validateBody(loginBodySchema), async (req, res) => {
  try {
    const email = req.body.email.toLowerCase().trim();
    const user = await UserModel.findOne({ email });

    if (!user) {
      return res.status(401).json({ error: 'InvalidCredentials' });
    }

    const ok = await verifyPassword(req.body.password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: 'InvalidCredentials' });
    }

    user.lastLoginAt = new Date();
    user.loginCount = (user.loginCount ?? 0) + 1;
    await user.save();

    const token = randomUUID();
    const refreshTokenHash = await hashPassword(token);

    await AuthSessionModel.create({
      userId: user._id,
      refreshTokenHash,
      userAgent: req.header('user-agent') ?? '',
      ipAddress: req.ip,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7),
    });

    return res.status(200).json({
      user: sanitizeUser(user),
      token,
    });
  } catch (error: unknown) {
    // eslint-disable-next-line no-console
    console.error('Login failed:', error);
    return res.status(500).json({ error: 'LoginFailed' });
  }
});
