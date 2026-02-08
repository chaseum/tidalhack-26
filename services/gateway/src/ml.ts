import { requestMl } from "./clients/ml";
import { config } from "./env";

export const mlAssess = async (formData: FormData): Promise<unknown> => {
  return requestMl(
    config.ML_BASE_URL,
    "/assess",
    {
      method: "POST",
      body: formData
    },
    config.REQUEST_TIMEOUT_MS
  );
};

export const mlPlan = async (body: unknown): Promise<unknown> => {
  return requestMl(
    config.ML_BASE_URL,
    "/plan",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    },
    config.REQUEST_TIMEOUT_MS
  );
};

export const mlChat = async (body: unknown): Promise<unknown> => {
  return requestMl(
    config.ML_BASE_URL,
    "/chat",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    },
    config.REQUEST_TIMEOUT_MS
  );
};
