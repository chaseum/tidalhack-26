from __future__ import annotations

from datetime import UTC, datetime
from threading import Lock
from typing import Any


class PetStore:
    def __init__(self) -> None:
        self._lock = Lock()
        self._data: dict[str, dict[str, Any]] = {}

    @staticmethod
    def _now_iso() -> str:
        return datetime.now(UTC).isoformat().replace("+00:00", "Z")

    def get(self, pet_id: str) -> dict[str, Any] | None:
        with self._lock:
            entry = self._data.get(pet_id)
            return dict(entry) if entry is not None else None

    def upsert_profile(
        self,
        pet_id: str,
        *,
        species: str,
        weight_kg: float,
        food: dict[str, float | None],
    ) -> dict[str, Any]:
        with self._lock:
            current = self._data.get(pet_id, {})
            updated = {
                **current,
                "pet_id": pet_id,
                "species": species,
                "weight_kg": weight_kg,
                "food": food,
                "last_assess": current.get("last_assess"),
                "last_plan": current.get("last_plan"),
                "updated_at": self._now_iso(),
            }
            self._data[pet_id] = updated
            return dict(updated)

    def save_last_assess(self, pet_id: str, assess: dict[str, Any]) -> dict[str, Any]:
        with self._lock:
            current = self._data.get(pet_id, {"pet_id": pet_id})
            current["last_assess"] = assess
            current.setdefault("last_plan", None)
            current["updated_at"] = self._now_iso()
            self._data[pet_id] = current
            return dict(current)

    def save_last_plan(self, pet_id: str, plan: dict[str, Any]) -> dict[str, Any]:
        with self._lock:
            current = self._data.get(pet_id, {"pet_id": pet_id})
            current["last_plan"] = plan
            current.setdefault("last_assess", None)
            current["updated_at"] = self._now_iso()
            self._data[pet_id] = current
            return dict(current)


pet_store = PetStore()
