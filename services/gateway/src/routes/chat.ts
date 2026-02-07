import { randomUUID } from "crypto";
import { Router } from "express";
import { chatRequestSchema, chatResponseSchema } from "../validators/contracts";
import { validateBody } from "../middleware/validate";

export const chatRouter = Router();

chatRouter.post("/", validateBody(chatRequestSchema), (req, res) => {
  const sessionId = req.body.session_id ?? randomUUID();
  const response = chatResponseSchema.parse({
    reply: `Mock reply: ${req.body.message}`,
    session_id: sessionId
  });

  res.status(200).json(response);
});
