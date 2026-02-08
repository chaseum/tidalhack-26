import dotenv from "dotenv";

dotenv.config();

const parseNumber = (value: string | undefined, fallback: number): number => {
  if (!value) {
    return fallback
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const parseBoolean = (value: string | undefined, fallback: boolean): boolean => {
  if (!value) {
    return fallback;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "true" || normalized === "1" || normalized === "yes") {
    return true;
  }
  if (normalized === "false" || normalized === "0" || normalized === "no") {
    return false;
  }
  return fallback;
};

export const config = {
  PORT: parseNumber(process.env.PORT ?? process.env.GATEWAY_PORT, 8080),
  ML_BASE_URL: process.env.ML_BASE_URL ?? "http://127.0.0.1:8000",
  RATE_LIMIT_RPM: parseNumber(process.env.RATE_LIMIT_RPM, 60),
  REQUEST_TIMEOUT_MS: parseNumber(process.env.REQUEST_TIMEOUT_MS, 8000),
  DEBUG: parseBoolean(process.env.DEBUG, false)
};
