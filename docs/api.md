# API Contract (Canonical)

This file is the single source of truth for the gateway API contract.

## Common Error Shape

All non-2xx responses use this JSON:

```json
{
  "error": {
    "code": "ValidationError",
    "message": "message describing the failure",
    "retryable": false
  }
}
```

## POST /assess

`Content-Type: multipart/form-data`

### Multipart Parts

1. `image` (required): binary file.
2. `request` (required): JSON string with this shape:

```json
{
  "pet_id": "pet_123",
  "species": "dog",
  "breed_hint": "corgi"
}
```

### Response JSON (200)

```json
{
  "species": "dog",
  "breed_top3": [
    { "breed": "labrador_retriever", "p": 0.62 },
    { "breed": "golden_retriever", "p": 0.21 },
    { "breed": "mixed", "p": 0.17 }
  ],
  "mask": { "available": true },
  "ratios": {
    "length_px": 180.0,
    "waist_to_chest": 0.78,
    "width_profile": [0.9, 0.88, 0.85, 0.8, 0.78],
    "belly_tuck": 0.03
  },
  "bucket": "OVERWEIGHT",
  "confidence": 0.82,
  "notes": "Waistline and body condition appear healthy."
}
```

Field rules:
- `species`: non-empty string, required.
- `breed_top3`: exactly 3 entries `{ breed: string, p: number[0,1] }`, required.
- `mask.available`: boolean, required.
- `ratios`: object with `length_px`, `waist_to_chest`, `width_profile[5]`, `belly_tuck`; nullable.
- `bucket`: one of `UNDERWEIGHT|IDEAL|OVERWEIGHT|OBESE|UNKNOWN`, required.
- `confidence`: number in `[0, 1]`, required.
- `notes`: non-empty string, required.

## POST /plan

`Content-Type: application/json`

### Request JSON

```json
{
  "pet_id": "pet_123",
  "species": "dog",
  "weight_kg": 10.0,
  "bucket": "IDEAL",
  "activity": "MODERATE",
  "goal": "MAINTAIN",
  "food": { "kcal_per_g": 3.5 }
}
```

Field rules:
- `pet_id`: non-empty string, required.
- `species`: one of `dog|cat`, required.
- `weight_kg`: number `> 0`, required.
- `bucket`: one of `UNDERWEIGHT|IDEAL|OVERWEIGHT|OBESE|UNKNOWN`, required.
- `activity`: one of `LOW|MODERATE|HIGH`, required.
- `goal`: one of `LOSE|MAINTAIN|GAIN`, required.
- `food`: either `kcal_per_g` OR both `kcal_per_cup` and `grams_per_cup`.

### Response JSON (200)

```json
{
  "pet_id": "pet_123",
  "species": "dog",
  "weight_kg": 10.0,
  "bucket": "IDEAL",
  "activity": "MODERATE",
  "goal": "MAINTAIN",
  "kcal_per_g": 3.5,
  "rer": 392.9895074300714,
  "multiplier": 1.4,
  "daily_calories": 550,
  "grams_per_day": 157,
  "disclaimer": "Educational estimate only. Confirm your pet's feeding plan with a licensed veterinarian."
}
```

Field rules:
- mirrors request context with normalized and computed values.
- `kcal_per_g`: normalized calories-per-gram (`> 0`), required.
- `rer`: number `> 0`, required.
- `multiplier`: number `> 0`, required.
- `daily_calories`: integer `> 0`, required.
- `grams_per_day`: integer `> 0`, required.
- `disclaimer`: non-empty string, required.

## POST /chat

`Content-Type: application/json`

### Request JSON

```json
{
  "message": "What should I focus on this week?",
  "session_id": "optional-session-id"
}
```

Field rules:
- `message`: non-empty string, required.
- `session_id`: non-empty string, optional.

### Response JSON (200)

```json
{
  "reply": "Focus on consistency: complete your meal log for 3 days this week.",
  "quick_actions": [
    "Log appetite this morning and evening.",
    "Check breathing rate while resting."
  ]
}
```

Field rules:
- `reply`: non-empty string, required.
- `quick_actions`: non-empty array of non-empty strings, required.
