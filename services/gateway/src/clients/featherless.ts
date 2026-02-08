const DEFAULT_FEATHERLESS_BASE_URL = "https://api.featherless.ai/v1";

const normalizeBaseUrl = (raw: string): string => raw.replace(/\/+$/, "");

export const featherlessBaseUrl = normalizeBaseUrl(
  process.env.FEATHERLESS_BASE_URL ?? DEFAULT_FEATHERLESS_BASE_URL
);

export function getFeatherlessHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json"
  };

  if (process.env.FEATHERLESS_API_KEY) {
    headers.Authorization = `Bearer ${process.env.FEATHERLESS_API_KEY}`;
  }

  return headers;
}
