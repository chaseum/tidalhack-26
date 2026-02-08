import base64
import json
import os
from json import JSONDecodeError
from typing import Any

from openai import APIConnectionError, APITimeoutError, OpenAI

FEATHERLESS_BASE_URL = "https://api.featherless.ai/v1"
VISION_MODEL = os.getenv("VISION_MODEL", "google/gemma-3-27b-it")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("FEATHERLESS_REQUEST_TIMEOUT_SECONDS", "30"))
RETRY_ATTEMPTS = 1

_client: OpenAI | None = None


def _get_client() -> OpenAI:
    global _client
    if _client is None:
        api_key = os.getenv("FEATHERLESS_API_KEY")
        if not api_key:
            raise RuntimeError("FEATHERLESS_API_KEY is not set")
        _client = OpenAI(
            api_key=api_key,
            base_url=FEATHERLESS_BASE_URL,
            timeout=REQUEST_TIMEOUT_SECONDS,
            max_retries=0,
        )
    return _client


def _extract_first_json_object(text: str) -> str | None:
    start = text.find("{")
    if start < 0:
        return None

    depth = 0
    in_string = False
    escape = False

    for i in range(start, len(text)):
        ch = text[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue

        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]

    return None


def _parse_json_response(full: str) -> dict[str, Any]:
    try:
        parsed = json.loads(full)
        if isinstance(parsed, dict):
            return parsed
        raise ValueError("Model output is valid JSON but not a JSON object")
    except JSONDecodeError:
        block = _extract_first_json_object(full)
        if not block:
            raise ValueError("Could not parse JSON object from model output")
        parsed = json.loads(block)
        if isinstance(parsed, dict):
            return parsed
        raise ValueError("Extracted JSON is not a JSON object")


def _request_vision_json(image_bytes: bytes, mime: str, prompt_text: str) -> str:
    image_b64 = base64.b64encode(image_bytes).decode("ascii")
    data_url = f"data:{mime};base64,{image_b64}"
    response = _get_client().chat.completions.create(
        model=VISION_MODEL,
        response_format={"type": "json_object"},
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"{prompt_text}\n\nReturn ONLY a strict JSON object.",
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": data_url},
                    },
                ],
            }
        ],
    )
    content = response.choices[0].message.content
    return content if content is not None else ""


def vision_json(image_bytes: bytes, mime: str, prompt_text: str) -> dict[str, Any]:
    full = ""
    for attempt in range(RETRY_ATTEMPTS + 1):
        try:
            full = _request_vision_json(
                image_bytes=image_bytes,
                mime=mime,
                prompt_text=prompt_text,
            )
            break
        except (APIConnectionError, APITimeoutError):
            if attempt >= RETRY_ATTEMPTS:
                raise
    return _parse_json_response(full)
