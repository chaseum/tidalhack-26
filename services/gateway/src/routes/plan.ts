import { Router } from "express";
import { mlPlan } from "../ml";
import { validateBody } from "../middleware/validate";
import { planRequestSchema, planResponseSchema } from "../validators/contracts";

export const planRouter = Router();

planRouter.post("/", validateBody(planRequestSchema), async (req, res, next) => {
  try {
    const upstreamResponse = await mlPlan(req.body);
    const response = planResponseSchema.parse(upstreamResponse);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
});
