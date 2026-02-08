import type { NextFunction, Request, Response } from "express";

const nowMs = (): number => Number(process.hrtime.bigint()) / 1_000_000;

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const startedAt = nowMs();

  res.on("finish", () => {
    const durationMs = Number((nowMs() - startedAt).toFixed(1));
    const payload = {
      level: "info",
      ts: new Date().toISOString(),
      msg: "request completed",
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      durationMs
    };

    // Emit structured logs in a pino-compatible JSON shape.
    console.log(JSON.stringify(payload));
  });

  next();
}
