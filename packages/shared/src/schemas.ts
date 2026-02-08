import { z } from "zod";

export const speciesSchema = z.enum(["dog", "cat"]);
export const bucketSchema = z.enum(["UNDERWEIGHT", "IDEAL", "OVERWEIGHT", "OBESE", "UNKNOWN"]);
export const activitySchema = z.enum(["LOW", "MODERATE", "HIGH"]);
export const goalSchema = z.enum(["LOSE", "MAINTAIN", "GAIN"]);

export const assessRequestSchema = z.object({
  pet_id: z.string().min(1).optional(),
  species: z.string().min(1).optional(),
  breed_hint: z.string().min(1).optional()
});

export const assessResponseSchema = z.object({
  species: z.string().min(1),
  breed_top3: z
    .array(
      z.object({
        breed: z.string().min(1),
        p: z.number().min(0).max(1)
      })
    )
    .length(3),
  mask: z.object({
    available: z.boolean()
  }),
  ratios: z
    .object({
      length_px: z.number(),
      waist_to_chest: z.number(),
      width_profile: z.array(z.number()).length(5),
      belly_tuck: z.number()
    })
    .nullable()
    .optional(),
  bucket: bucketSchema,
  confidence: z.number().min(0).max(1),
  notes: z.string().min(1)
});

export const planRequestSchema = z.object({
  pet_id: z.string().min(1),
  species: speciesSchema,
  weight_kg: z.number().positive(),
  bucket: bucketSchema,
  activity: activitySchema,
  goal: goalSchema,
  food: z
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
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Provide kcal_per_g or kcal_per_cup with grams_per_cup."
      });
    })
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
