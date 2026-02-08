from __future__ import annotations

import os
from dataclasses import dataclass


def _as_float(name: str, default: float) -> float:
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        return float(raw)
    except ValueError:
        return default


def _as_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("ML_APP_NAME", "ML Service")
    log_level: str = os.getenv("ML_LOG_LEVEL", "INFO").upper()
    host: str = os.getenv("ML_HOST", "127.0.0.1")
    port: int = _as_int("ML_PORT", 8000)
    request_timeout_seconds: float = _as_float("ML_REQUEST_TIMEOUT_SECONDS", 8.0)


settings = Settings()
