import { config } from "./env";

const MAX_ERROR_TEXT_LENGTH = 500;

const truncate = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, maxLength)}...`;
};

const readErrorText = async (response: Response): Promise<string> => {
  try {
    return truncate(await response.text(), MAX_ERROR_TEXT_LENGTH);
  } catch {
    return "<failed to read response body>";
  }
};

const requestMl = async (path: string, init: RequestInit): Promise<unknown> => {
  const response = await fetch(`${config.ML_BASE_URL}${path}`, {
    ...init,
    signal: AbortSignal.timeout(config.REQUEST_TIMEOUT_MS)
  });

  if (!response.ok) {
    const responseText = await readErrorText(response);
    const upstreamError = new Error(
      `ML request failed: status=${response.status} body=${responseText}`
    ) as Error & { status?: number; code?: string };
    upstreamError.status = response.status >= 400 && response.status <= 599 ? response.status : 502;
    upstreamError.code = "UpstreamError";
    throw upstreamError;
  }

  return response.json();
};

export const mlAssess = async (formData: FormData): Promise<unknown> => {
  return requestMl("/assess", {
    method: "POST",
    body: formData
  });
};

export const mlPlan = async (body: unknown): Promise<unknown> => {
  return requestMl("/plan", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
};

export const mlChat = async (body: unknown): Promise<unknown> => {
  return requestMl("/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
};
