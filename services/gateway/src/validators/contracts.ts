import { z } from "zod";

const speciesSchema = z.enum(["dog", "cat"]);
const bucketSchema = z.enum(["UNDERWEIGHT", "IDEAL", "OVERWEIGHT", "OBESE", "UNKNOWN"]);
const activitySchema = z.enum(["LOW", "MODERATE", "HIGH"]);
const goalSchema = z.enum(["LOSE", "MAINTAIN", "GAIN"]);

export const assessRequestSchema = z.object({
  pet_id: z.string().min(1).optional(),
  species: z.string().min(1).optional(),
  breed_hint: z.string().min(1).optional()
  // Optional metadata forwarded to ML.
});

const breedProbSchema = z.object({
  breed: z.string().min(1),
  p: z.number().min(0).max(1)
});

const assessRatiosSchema = z.object({
  length_px: z.number(),
  waist_to_chest: z.number(),
  width_profile: z.array(z.number()).length(5),
  belly_tuck: z.number()
});

export const assessResponseSchema = z.object({
  species: z.string().min(1),
  breed_top3: z.array(breedProbSchema).length(3),
  mask: z.object({
    available: z.boolean()
  }),
  ratios: assessRatiosSchema.nullable().optional(),
  bucket: bucketSchema,
  confidence: z.number().min(0).max(1),
  notes: z.string()
});

const planFoodSchema = z
  .object({
    kcal_per_g: z.number().positive().optional(),
    kcal_per_cup: z.number().positive().optional(),
    grams_per_cup: z.number().positive().optional()
  })
  .superRefine((value, ctx) => {
    if (value.kcal_per_g !== undefined) {
      return;
    }
    if (value.kcal_per_cup !== undefined && value.grams_per_cup !== undefined) {
      return;
    }
    if (value.kcal_per_cup === undefined && value.grams_per_cup === undefined) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Provide kcal_per_g or kcal_per_cup with grams_per_cup."
      });
      return;
    }
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "kcal_per_cup and grams_per_cup must be provided together."
    });
  });

export const planRequestSchema = z.object({
  pet_id: z.string().min(1),
  species: speciesSchema,
  weight_kg: z.number().positive(),
  bucket: bucketSchema,
  activity: activitySchema,
  goal: goalSchema,
  food: planFoodSchema
});

export const planResponseSchema = z.object({
  pet_id: z.string().min(1),
  species: speciesSchema,
  weight_kg: z.number().positive(),
  bucket: bucketSchema,
  activity: activitySchema,
  goal: goalSchema,
  kcal_per_g: z.number().positive(),
  rer: z.number().positive(),
  multiplier: z.number().positive(),
  daily_calories: z.number().int().positive(),
  grams_per_day: z.number().int().positive(),
  disclaimer: z.string().min(1)
});

export const chatRequestSchema = z.object({
  message: z.string().min(1),
  session_id: z.string().min(1).optional()
});

export const chatResponseSchema = z.object({
  reply: z.string().min(1),
  quick_actions: z.array(z.string().min(1)).min(1)
});

export type AssessRequest = z.infer<typeof assessRequestSchema>;
export type AssessResponse = z.infer<typeof assessResponseSchema>;
export type PlanRequest = z.infer<typeof planRequestSchema>;
export type PlanResponse = z.infer<typeof planResponseSchema>;
export type ChatRequest = z.infer<typeof chatRequestSchema>;
export type ChatResponse = z.infer<typeof chatResponseSchema>;
