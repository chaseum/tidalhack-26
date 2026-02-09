import os
from typing import Any, Sequence

from openai import APIConnectionError, APITimeoutError, OpenAI

DEFAULT_FEATHERLESS_BASE_URL = "https://api.featherless.ai/v1"
FEATHERLESS_BASE_URL = os.getenv("FEATHERLESS_BASE_URL", DEFAULT_FEATHERLESS_BASE_URL)
FEATHERLESS_SECRET_HEADER = os.getenv(
    "FEATHERLESS_SECRET_HEADER", "X-Featherless-Secret-Key"
)
VISION_MODEL = os.getenv("VISION_MODEL", "google/gemma-3-27b-it")
CHAT_MODEL = os.getenv("CHAT_MODEL", "meta-llama/Meta-Llama-3.1-8B-Instruct")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("FEATHERLESS_REQUEST_TIMEOUT_SECONDS", "30"))

_client: OpenAI | None = None


def get_client() -> OpenAI:
    global _client
    if _client is None:
        api_key = os.getenv("FEATHERLESS_API_KEY")
        if not api_key:
            raise RuntimeError("FEATHERLESS_API_KEY is not set")
        default_headers: dict[str, str] = {}
        secret_key = os.getenv("FEATHERLESS_SECRET_KEY")
        if secret_key:
            default_headers[FEATHERLESS_SECRET_HEADER] = secret_key
        _client = OpenAI(
            api_key=api_key,
            base_url=FEATHERLESS_BASE_URL,
            timeout=REQUEST_TIMEOUT_SECONDS,
            max_retries=0,
            default_headers=default_headers,
        )
    return _client


def _chat_once(
    model: str,
    messages: Sequence[dict[str, Any]],
    timeout_seconds: float | None = None,
) -> str:
    response = get_client().chat.completions.create(
        model=model,
        messages=list(messages),
        timeout=timeout_seconds,
    )
    content = response.choices[0].message.content
    return content if content is not None else ""


def _chat_with_single_retry(
    model: str,
    messages: Sequence[dict[str, Any]],
    timeout_seconds: float | None = None,
) -> str:
    try:
        return _chat_once(model=model, messages=messages, timeout_seconds=timeout_seconds)
    except (APIConnectionError, APITimeoutError):
        return _chat_once(model=model, messages=messages, timeout_seconds=timeout_seconds)


def vision_chat(messages: Sequence[dict[str, Any]]) -> str:
    return _chat_with_single_retry(model=VISION_MODEL, messages=messages)


def text_chat(messages: Sequence[dict[str, Any]], timeout_seconds: float | None = None) -> str:
    return _chat_with_single_retry(
        model=CHAT_MODEL,
        messages=messages,
        timeout_seconds=timeout_seconds,
    )
