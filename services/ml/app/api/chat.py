from __future__ import annotations

import json
import re
from typing import Any

from fastapi import APIRouter
from openai import APIConnectionError, APITimeoutError

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.featherless_client import text_chat

router = APIRouter()

CHAT_TIMEOUT_SECONDS = 8.0
MAX_REPLY_SENTENCES = 6
MAX_QUICK_ACTIONS = 4

SYSTEM_PROMPT = (
    "You are a pet wellness assistant. Follow rules strictly: "
    "reply in no more than 6 sentences; "
    "make steps actionable today; "
    "if there are red flags, tell the user to contact a veterinarian or emergency ER now; "
    "do not diagnose; "
    "do not give medication dosing. "
    "Return only strict JSON with keys: reply (string), quick_actions (array of short strings)."
)

FALLBACK_REPLY = (
    "I cannot provide full guidance right now. Keep your pet calm and monitor breathing, appetite, "
    "energy, bathroom habits, and comfort today. If there is trouble breathing, collapse, seizures, "
    "uncontrolled bleeding, toxin exposure, severe pain, or inability to urinate, go to a vet ER now."
)
FALLBACK_ACTIONS = [
    "Check breathing, gum color, and alertness now.",
    "Offer water if safe and note any vomiting, diarrhea, or urination changes today.",
    "Contact your vet today for same-day advice if symptoms persist or worsen.",
]


def _truncate_to_sentence_limit(text: str, max_sentences: int = MAX_REPLY_SENTENCES) -> str:
    normalized = " ".join(text.strip().split())
    if not normalized:
        return FALLBACK_REPLY

    sentence_matches = list(re.finditer(r"[^.!?]+[.!?]?", normalized))
    if not sentence_matches:
        return normalized
    if len(sentence_matches) <= max_sentences:
        return normalized
    return normalized[: sentence_matches[max_sentences - 1].end()].strip()


def _extract_json_block(raw: str) -> dict[str, Any]:
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            return parsed
    except json.JSONDecodeError:
        pass

    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found in model output.")
    parsed = json.loads(raw[start : end + 1])
    if not isinstance(parsed, dict):
        raise ValueError("Model output JSON is not an object.")
    return parsed


def _normalize_quick_actions(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    actions: list[str] = []
    for item in value:
        if not isinstance(item, str):
            continue
        text = " ".join(item.strip().split())
        if text:
            actions.append(text)
        if len(actions) >= MAX_QUICK_ACTIONS:
            break
    return actions


def _fallback_response() -> ChatResponse:
    return ChatResponse(reply=FALLBACK_REPLY, quick_actions=FALLBACK_ACTIONS)


@router.post("/chat", response_model=ChatResponse)
def chat(payload: ChatRequest) -> ChatResponse:
    _ = payload.session_id
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": payload.message.strip()},
    ]

    try:
        raw = text_chat(messages=messages, timeout_seconds=CHAT_TIMEOUT_SECONDS)
        parsed = _extract_json_block(raw)
        reply = _truncate_to_sentence_limit(str(parsed.get("reply", "")).strip())
        quick_actions = _normalize_quick_actions(parsed.get("quick_actions"))
        if not reply or not quick_actions:
            return _fallback_response()
        return ChatResponse(reply=reply, quick_actions=quick_actions)
    except (APIConnectionError, APITimeoutError, RuntimeError, ValueError, KeyError, TypeError):
        return _fallback_response()
