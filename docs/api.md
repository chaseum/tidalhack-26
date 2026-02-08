## POST /assess

Request example:

```json
{
  "image_url": "https://example.com/pet.jpg",
  "meta": {
    "species": "dog",
    "breed_hint": "corgi",
    "weight_kg": 12.5
  }
}
```

Response example:

```json
{
  "species": "dog",
  "breed_top3": [
    { "breed": "labrador_retriever", "p": 0.62 },
    { "breed": "golden_retriever", "p": 0.21 },
    { "breed": "flat_coated_retriever", "p": 0.07 }
  ],
  "mask": { "available": true },
  "ratios": {
    "length_px": 812,
    "waist_to_chest": 0.78,
    "width_profile": [0.92, 0.88, 0.81, 0.79, 0.83],
    "belly_tuck": 0.14
  },
  "bucket": "OVERWEIGHT",
  "confidence": 0.74,
  "notes": "Waist is present but reduced; tuck is mild."
}
```

## POST /plan

Request example:

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "goal": "Improve diet quality over 30 days",
  "constraints": ["budget-friendly", "beginner"]
}
```

Response example:

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "plan": [
    "Week 1: establish baseline meals",
    "Week 2: replace one processed meal/day",
    "Week 3: add fiber + hydration targets",
    "Week 4: review and adjust"
  ],
  "next_step": "Track meals for 3 days"
}
```

## POST /chat

Request example:

```json
{
  "message": "Hello, what can you tell me about sustainable investing?",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
}
```

Response example:

```json
{
  "reply": "Sustainable investing considers environmental, social, and governance (ESG) factors. Would you like to know more about a specific area?",
  "session_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
}
```
