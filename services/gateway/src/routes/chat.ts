import { Router } from "express";
import { mlChat } from "../ml";
import { validateBody } from "../middleware/validate";
import { chatRequestSchema, chatResponseSchema } from "../validators/contracts";

export const chatRouter = Router();

chatRouter.post("/", validateBody(chatRequestSchema), async (req, res, next) => {
  try {
    const upstreamResponse = await mlChat(req.body);
    const response = chatResponseSchema.parse(upstreamResponse);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
});
