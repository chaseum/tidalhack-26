import type { NextFunction, Request, Response } from "express";
import { Types } from "mongoose";
import { sendError } from "../error-response";

const USER_ID_HEADER = "x-user-id";

export function parseUserObjectId(headerValue: string | undefined): Types.ObjectId | null {
  if (!headerValue || !Types.ObjectId.isValid(headerValue)) {
    return null;
  }
  return new Types.ObjectId(headerValue);
}

export function requireUserId(req: Request, res: Response, next: NextFunction) {
  const parsed = parseUserObjectId(req.header(USER_ID_HEADER));
  if (!parsed) {
    return sendError(
      res,
      401,
      "ValidationError",
      `Missing or invalid ${USER_ID_HEADER} header.`
    );
  }

  res.locals.userObjectId = parsed;
  return next();
}

export function getUserObjectId(res: Response): Types.ObjectId {
  return res.locals.userObjectId as Types.ObjectId;
}
