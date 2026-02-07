# HTTP Contracts

This document outlines the HTTP endpoints for the service.

## Endpoints

### POST /predict

Analyzes an image and returns a set of scores and a confidence level.

- **Request body:** See `schemas/predict.json`
- **Response body:** See `schemas/predict.json`

### POST /assess

A proxy for the `/predict` endpoint. It takes the same request and returns the same response.

- **Request body:** See `schemas/assess.json`
- **Response body:** See `schemas/assess.json`

### POST /chat

Proxies requests to the Featherless chat service.

- **Request body:** See `schemas/chat.json`
- **Response body:** See `schemas/chat.json`