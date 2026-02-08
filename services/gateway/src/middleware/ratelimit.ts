import type { NextFunction, Request, Response } from "express";
import { sendError } from "../error-response";
import { config } from "../env";

type Bucket = {
  count: number;
  resetAt: number;
};

const WINDOW_MS = 60_000;
const buckets = new Map<string, Bucket>();

const now = (): number => Date.now();

const keyFor = (req: Request): string => {
  const forwarded = req.header("x-forwarded-for");
  const firstForwarded = forwarded?.split(",")[0]?.trim();
  const ip = firstForwarded || req.ip || "unknown";
  return `${ip}:${req.path}`;
};

export function rateLimit(req: Request, res: Response, next: NextFunction) {
  if (req.method === "OPTIONS" || req.path === "/health") {
    return next();
  }

  const limit = Math.max(1, Math.floor(config.RATE_LIMIT_RPM));
  const key = keyFor(req);
  const currentTime = now();
  const existing = buckets.get(key);

  if (!existing || currentTime >= existing.resetAt) {
    buckets.set(key, { count: 1, resetAt: currentTime + WINDOW_MS });
    return next();
  }

  if (existing.count >= limit) {
    const retryAfterSeconds = Math.max(1, Math.ceil((existing.resetAt - currentTime) / 1000));
    res.setHeader("Retry-After", String(retryAfterSeconds));
    return sendError(
      res,
      429,
      "RateLimitExceeded",
      `Rate limit exceeded. Try again in ${retryAfterSeconds}s.`
    );
  }

  existing.count += 1;
  buckets.set(key, existing);
  return next();
}
