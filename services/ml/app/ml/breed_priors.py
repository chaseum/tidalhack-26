from __future__ import annotations

from csv import DictReader
from functools import lru_cache
from pathlib import Path
from typing import Any

REQUIRED_COLUMNS: tuple[str, ...] = (
    "species",
    "breed",
    "min_weight_kg",
    "max_weight_kg",
    "size_class",
)


def _normalize(text: str) -> str:
    return " ".join(text.strip().lower().split())


def _priors_csv_path() -> Path:
    # services/ml/app/ml/breed_priors.py -> repo_root/data/breed_priors.csv
    return Path(__file__).resolve().parents[4] / "data" / "breed_priors.csv"


@lru_cache(maxsize=1)
def load_priors() -> dict[str, dict[str, dict[str, Any]]]:
    priors: dict[str, dict[str, dict[str, Any]]] = {}

    with _priors_csv_path().open(newline="", encoding="utf-8") as handle:
        reader = DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError("breed_priors.csv is missing a header row")

        missing = [col for col in REQUIRED_COLUMNS if col not in reader.fieldnames]
        if missing:
            raise ValueError(f"breed_priors.csv missing required columns: {missing}")

        for row in reader:
            species = _normalize(row["species"])
            breed = _normalize(row["breed"])
            min_weight = float(row["min_weight_kg"])
            max_weight = float(row["max_weight_kg"])

            if max_weight < min_weight:
                raise ValueError(
                    f"Invalid weight range for {row['species']} / {row['breed']}"
                )

            priors.setdefault(species, {})[breed] = {
                "species": row["species"].strip(),
                "breed": row["breed"].strip(),
                "min_weight_kg": min_weight,
                "max_weight_kg": max_weight,
                "size_class": row["size_class"].strip(),
            }

    return priors


def plausible_weight(breed: str, species: str, weight_kg: float) -> bool | None:
    species_priors = load_priors().get(_normalize(species))
    if species_priors is None:
        return None

    prior = species_priors.get(_normalize(breed))
    if prior is None:
        return None

    return prior["min_weight_kg"] <= float(weight_kg) <= prior["max_weight_kg"]
