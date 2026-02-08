import type { NextFunction, Request, Response } from "express";

export type HttpError = Error & {
  status?: number;
  detail?: string;
};

const isHttpError = (value: unknown): value is HttpError => {
  return typeof value === "object" && value !== null;
};

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  const status =
    isHttpError(err) && typeof err.status === "number" && err.status >= 100 && err.status <= 599
      ? err.status
      : 502;

  const error = err instanceof Error ? err.name || "Error" : "Error";
  const detail =
    isHttpError(err) && typeof err.detail === "string"
      ? err.detail
      : err instanceof Error
        ? err.message
        : "Unexpected gateway error";

  res.status(status).json({ error, detail });
}
