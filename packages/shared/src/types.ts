export type Species = "dog" | "cat";
export type BcsBucket = "UNDERWEIGHT" | "IDEAL" | "OVERWEIGHT" | "OBESE" | "UNKNOWN";
export type ActivityLevel = "LOW" | "MODERATE" | "HIGH";
export type Goal = "LOSE" | "MAINTAIN" | "GAIN";

export type AssessRequest = {
  pet_id?: string;
  species?: string;
  breed_hint?: string;
};

export type AssessResponse = {
  species: string;
  breed_top3: Array<{ breed: string; p: number }>;
  mask: { available: boolean };
  ratios?:
    | {
        length_px: number;
        waist_to_chest: number;
        width_profile: [number, number, number, number, number];
        belly_tuck: number;
      }
    | null;
  bucket: BcsBucket;
  confidence: number;
  notes: string;
};

export type PlanRequest = {
  pet_id: string;
  species: Species;
  weight_kg: number;
  bucket: BcsBucket;
  activity: ActivityLevel;
  goal: Goal;
  food:
    | {
        kcal_per_g: number;
      }
    | {
        kcal_per_cup: number;
        grams_per_cup: number;
      };
};

export type PlanResponse = {
  pet_id: string;
  species: Species;
  weight_kg: number;
  bucket: BcsBucket;
  activity: ActivityLevel;
  goal: Goal;
  kcal_per_g: number;
  rer: number;
  multiplier: number;
  daily_calories: number;
  grams_per_day: number;
  disclaimer: string;
};

export type ChatRequest = {
  message: string;
  session_id?: string;
};

export type ChatResponse = {
  reply: string;
  quick_actions: string[];
};
