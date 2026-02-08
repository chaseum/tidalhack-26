import type { Response } from "express";

type GatewayErrorCode =
  | "ValidationError"
  | "NotFound"
  | "UpstreamError"
  | "InternalError";

type ErrorBody = {
  error: {
    code: GatewayErrorCode | string;
    message: string;
    retryable: boolean;
  };
};

const isRetryableStatus = (status: number): boolean => status >= 500;

export const sendError = (
  res: Response,
  status: number,
  code: GatewayErrorCode | string,
  message: string
): Response<ErrorBody> => {
  return res.status(status).json({
    error: {
      code,
      message,
      retryable: isRetryableStatus(status)
    }
  });
};

