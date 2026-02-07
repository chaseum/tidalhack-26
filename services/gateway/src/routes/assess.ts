import { Router } from "express";
import { assessRequestSchema, assessResponseSchema } from "../validators/contracts";
import { validateBody } from "../middleware/validate";

export const assessRouter = Router();

assessRouter.post("/", validateBody(assessRequestSchema), (_req, res) => {
  const response = assessResponseSchema.parse({
    scores: {
      environmental: 0.7,
      social: 0.5,
      governance: 0.8
    },
    confidence: 0.82
  });

  res.status(200).json(response);
});
