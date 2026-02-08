import type { NextFunction, Request, Response } from "express";
import type { ZodTypeAny } from "zod";
import { sendError } from "../error-response";

export function validateBody(schema: ZodTypeAny) {
  return (req: Request, res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      const message = parsed.error.issues
        .map((issue) => `${issue.path.join(".") || "body"}: ${issue.message}`)
        .join("; ");
      return sendError(res, 400, "ValidationError", message || "Invalid request payload.");
    }
    req.body = parsed.data;
    next();
  };
}
