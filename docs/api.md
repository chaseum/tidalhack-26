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
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "species": "dog",
  "breed_hint": "corgi"
}
```

### Response JSON (200)

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "scores": {
    "environmental": 0.7,
    "social": 0.5,
    "governance": 0.8
  },
  "confidence": 0.82,
  "fallback_used": false,
  "notes": "Waistline and body condition appear healthy."
}
```

Field rules:
- `session_id`: UUID string, required.
- `scores.environmental|social|governance`: number in `[0, 1]`, required.
- `confidence`: number in `[0, 1]`, required.
- `fallback_used`: boolean, required.
- `notes`: string, optional.

### Happy Path Example

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "scores": {
    "environmental": 0.72,
    "social": 0.58,
    "governance": 0.81
  },
  "confidence": 0.84,
  "fallback_used": false,
  "notes": "Assessment completed from uploaded image."
}
```

### Failure/Fallback Example

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "scores": {
    "environmental": 0.5,
    "social": 0.5,
    "governance": 0.5
  },
  "confidence": 0.2,
  "fallback_used": true,
  "notes": "Low-quality image; fallback baseline scores returned."
}
```

## POST /plan

`Content-Type: application/json`

### Request JSON

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "goal": "Improve diet quality over 30 days",
  "constraints": ["budget-friendly", "beginner"],
  "horizon_days": 30
}
```

Field rules:
- `session_id`: UUID string, required.
- `goal`: non-empty string, required.
- `constraints`: array of strings, optional.
- `horizon_days`: integer in `[1, 90]`, optional (default `30`).

### Response JSON (200)

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "plan": [
    "Week 1: establish baseline meals",
    "Week 2: replace one processed meal/day",
    "Week 3: add hydration + fiber target",
    "Week 4: review and adjust"
  ],
  "next_step": "Track meals for 3 days",
  "fallback_used": false
}
```

Field rules:
- `session_id`: UUID string, required.
- `plan`: non-empty array of strings, required.
- `next_step`: non-empty string, required.
- `fallback_used`: boolean, required.

### Happy Path Example

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "plan": [
    "Week 1: establish baseline meals",
    "Week 2: replace one processed meal/day",
    "Week 3: add hydration + fiber target",
    "Week 4: review and adjust"
  ],
  "next_step": "Track meals for 3 days",
  "fallback_used": false
}
```

### Failure/Fallback Example

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "plan": [
    "Day 1: use a simple balanced-meal template",
    "Day 2: repeat template and log adherence"
  ],
  "next_step": "Retry detailed planning in a few minutes",
  "fallback_used": true
}
```

## POST /chat

`Content-Type: application/json`

### Request JSON

```json
{
  "message": "What should I focus on this week?",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
}
```

Field rules:
- `message`: non-empty string, required.
- `session_id`: UUID string, optional.

### Response JSON (200)

```json
{
  "reply": "Focus on consistency: complete your meal log for 3 days this week.",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "fallback_used": false
}
```

Field rules:
- `reply`: non-empty string, required.
- `session_id`: UUID string, required.
- `fallback_used`: boolean, required.

### Happy Path Example

```json
{
  "reply": "Great progress so far. This week, prioritize hydration and one high-fiber meal per day.",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "fallback_used": false
}
```

### Failure/Fallback Example

```json
{
  "reply": "I am temporarily unavailable for detailed guidance. Please try again shortly.",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "fallback_used": true
}
```
