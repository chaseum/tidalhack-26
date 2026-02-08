import { Router } from "express";
import { mlChat } from "../ml";
import { validateBody } from "../middleware/validate";
import { chatRequestSchema, chatResponseSchema } from "../validators/contracts";

export const chatRouter = Router();

const CHAT_FALLBACK_RESPONSE = chatResponseSchema.parse({
  reply:
    "I cannot provide a full AI response right now. Keep your pet calm and monitor breathing, appetite, energy, bathroom habits, and comfort today.",
  quick_actions: [
    "Check breathing, gum color, and alertness now.",
    "Offer water if safe and note vomiting, diarrhea, or urination changes today.",
    "Contact your vet today for same-day advice if symptoms persist or worsen."
  ]
});

const isUpstreamFailure = (error: unknown): boolean => {
  if (!(error instanceof Error)) {
    return false;
  }

  const withStatus = error as Error & { status?: number; code?: string };
  if (withStatus.code === "UpstreamError") {
    return true;
  }
  if (typeof withStatus.status === "number" && withStatus.status >= 500) {
    return true;
  }

  const message = error.message.toLowerCase();
  return (
    message.includes("fetch failed") ||
    message.includes("econnrefused") ||
    message.includes("timed out") ||
    message.includes("etimedout")
  );
};

chatRouter.post("/", validateBody(chatRequestSchema), async (req, res, next) => {
  try {
    const upstreamResponse = await mlChat(req.body);
    const response = chatResponseSchema.parse(upstreamResponse);
    res.status(200).json(response);
  } catch (error) {
    if (isUpstreamFailure(error)) {
      console.warn(
        JSON.stringify({
          level: "warn",
          ts: new Date().toISOString(),
          msg: "chat upstream unavailable, returning fallback response",
          error: error instanceof Error ? error.message : "unknown"
        })
      );
      res.status(200).json(CHAT_FALLBACK_RESPONSE);
      return;
    }
    next(error);
  }
});
