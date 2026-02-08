# HTTP Contracts

This document outlines the HTTP endpoints for the services.

## Gateway Service

### GET /health

Checks the health of the gateway service.

**Request:**
```
GET /health HTTP/1.1
```

**Response: 200 OK**
```json
{
  "status": "ok"
}
```

**Response: 503 Service Unavailable**
```json
{
  "status": "error",
  "details": "ML service is unavailable"
}
```

### POST /assess

Assesses a list of items.

**Request:**
See `schemas/assess.json` for the full schema.

*Example 1:*
```json
{
  "items": [
    { "id": "item1", "data": "Some data to assess" },
    { "id": "item2", "data": "Some other data to assess" }
  ]
}
```

*Example 2:*
```json
{
  "items": [
    { "id": "item3", "data": "Assess this please" }
  ]
}
```

**Response: 200 OK**
See `schemas/assess.json` for the full schema.

*Example 1:*
```json
{
  "results": [
    { "id": "item1", "assessment": "positive", "score": 0.9 },
    { "id": "item2", "assessment": "negative", "score": 0.2 }
  ]
}
```

*Example 2:*
```json
{
  "results": [
    { "id": "item3", "assessment": "neutral", "score": 0.5 }
  ]
}
```

### POST /chat

Handles chat messages.

**Request:**
See `schemas/chat.json` for the full schema.

*Example 1:*
```json
{
  "conversation_id": "conv123",
  "messages": [
    { "role": "user", "content": "Hello, world!" }
  ]
}
```

*Example 2:*
```json
{
  "messages": [
    { "role": "user", "content": "What is the weather like?" }
  ]
}
```

**Response: 200 OK**
See `schemas/chat.json` for the full schema.

*Example 1:*
```json
{
  "conversation_id": "conv123",
  "messages": [
    { "role": "assistant", "content": "Hello! How can I help you today?" }
  ]
}
```

*Example 2:*
```json
{
    "conversation_id": "conv456",
    "messages": [
        { "role": "assistant", "content": "I am not a weather bot, but I can help with other things!" }
    ]
}
```

## ML Service

### POST /predict

Predicts based on input data.

**Request:**
See `schemas/predict.json` for the full schema.

*Example 1:*
```json
{
  "inputs": [
    { "id": "input1", "features": [0.1, 0.2, 0.3] }
  ]
}
```

*Example 2:*
```json
{
  "inputs": [
    { "id": "input2", "features": [0.4, 0.5, 0.6] },
    { "id": "input3", "features": [0.7, 0.8, 0.9] }
  ]
}
```

**Response: 200 OK**
See `schemas/predict.json` for the full schema.

*Example 1:*
```json
{
  "predictions": [
    { "id": "input1", "prediction": "class_A", "confidence": 0.95 }
  ]
}
```

*Example 2:*
```json
{
  "predictions": [
    { "id": "input2", "prediction": "class_B", "confidence": 0.88 },
    { "id": "input3", "prediction": "class_A", "confidence": 0.92 }
  ]
}
```