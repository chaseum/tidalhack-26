import { z } from "zod";

const metricScoresSchema = z.object({
  environmental: z.number(),
  social: z.number(),
  governance: z.number()
});

export const assessRequestSchema = z.object({
  session_id: z.string().uuid(),
  species: z.string().min(1),
  breed_hint: z.string().min(1).optional()
});

export const assessResponseSchema = z.object({
  session_id: z.string().uuid(),
  scores: metricScoresSchema,
  confidence: z.number().min(0).max(1),
  fallback_used: z.boolean(),
  notes: z.string().optional()
});

export const planRequestSchema = z.object({
  session_id: z.string().uuid(),
  goal: z.string().min(1),
  constraints: z.array(z.string().min(1)).optional(),
  horizon_days: z.number().int().min(1).max(90).optional()
});

export const planResponseSchema = z.object({
  session_id: z.string().uuid(),
  plan: z.array(z.string().min(1)).min(1),
  next_step: z.string().min(1),
  fallback_used: z.boolean()
});

export const chatRequestSchema = z.object({
  message: z.string().min(1),
  session_id: z.string().uuid().optional()
});

export const chatResponseSchema = z.object({
  reply: z.string().min(1),
  session_id: z.string().uuid(),
  fallback_used: z.boolean()
});

export type AssessRequest = z.infer<typeof assessRequestSchema>;
export type AssessResponse = z.infer<typeof assessResponseSchema>;
export type PlanRequest = z.infer<typeof planRequestSchema>;
export type PlanResponse = z.infer<typeof planResponseSchema>;
export type ChatRequest = z.infer<typeof chatRequestSchema>;
export type ChatResponse = z.infer<typeof chatResponseSchema>;
