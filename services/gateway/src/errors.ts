import type { NextFunction, Request, Response } from "express";
import { sendError } from "./error-response";

export type HttpError = Error & {
  status?: number;
  code?: string;
  message?: string;
};

const isHttpError = (value: unknown): value is HttpError => {
  return typeof value === "object" && value !== null;
};

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  const status =
    isHttpError(err) && typeof err.status === "number" && err.status >= 100 && err.status <= 599
      ? err.status
      : 502;

  const code =
    isHttpError(err) && typeof err.code === "string"
      ? err.code
      : status >= 500
        ? "UpstreamError"
        : "InternalError";
  const message =
    isHttpError(err) && typeof err.message === "string" && err.message.trim().length > 0
      ? err.message
      : err instanceof Error
        ? err.message
        : "Unexpected gateway error";

  sendError(res, status, code, message);
}
