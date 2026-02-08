#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from urllib import error, request

DEFAULT_BASE_URL = "http://localhost:8000"
DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "demo_profiles.json"


def _post_profile(base_url: str, profile: dict) -> tuple[int, str]:
    pet_id = profile["pet_id"]
    payload = {
        "species": profile["species"],
        "weight_kg": profile["weight_kg"],
        "food": profile["food"],
    }
    req = request.Request(
        url=f"{base_url.rstrip('/')}/pet/{pet_id}",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with request.urlopen(req, timeout=10) as resp:
        body = resp.read().decode("utf-8")
        return resp.status, body


def main() -> int:
    base_url = os.getenv("ML_BASE_URL", DEFAULT_BASE_URL)
    try:
        profiles = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"Missing seed file: {DATA_PATH}", file=sys.stderr)
        return 1

    if not isinstance(profiles, list):
        print("Seed file must contain a JSON array.", file=sys.stderr)
        return 1

    failures = 0
    for profile in profiles:
        if not isinstance(profile, dict) or "pet_id" not in profile:
            print(f"Skipping invalid profile entry: {profile!r}", file=sys.stderr)
            failures += 1
            continue
        pet_id = profile["pet_id"]
        try:
            status, body = _post_profile(base_url, profile)
            print(f"{pet_id}: {status} {body}")
        except error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            print(f"{pet_id}: HTTP {exc.code} {body}", file=sys.stderr)
            failures += 1
        except Exception as exc:
            print(f"{pet_id}: ERROR {exc}", file=sys.stderr)
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
