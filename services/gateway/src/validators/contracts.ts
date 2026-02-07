import { z } from "zod";

export const scoreSchema = z.object({
  environmental: z.number(),
  social: z.number(),
  governance: z.number()
});

export const predictRequestSchema = z.object({
  image_url: z.string().url()
});

export const predictResponseSchema = z.object({
  scores: scoreSchema,
  confidence: z.number().min(0).max(1)
});

export const assessRequestSchema = z.object({
  image_url: z.string().url()
});

export const assessResponseSchema = z.object({
  scores: scoreSchema,
  confidence: z.number().min(0).max(1)
});

export const chatRequestSchema = z.object({
  message: z.string(),
  session_id: z.string().uuid().optional()
});

export const chatResponseSchema = z.object({
  reply: z.string(),
  session_id: z.string().uuid()
});

export type PredictRequest = z.infer<typeof predictRequestSchema>;
export type PredictResponse = z.infer<typeof predictResponseSchema>;
export type AssessRequest = z.infer<typeof assessRequestSchema>;
export type AssessResponse = z.infer<typeof assessResponseSchema>;
export type ChatRequest = z.infer<typeof chatRequestSchema>;
export type ChatResponse = z.infer<typeof chatResponseSchema>;
