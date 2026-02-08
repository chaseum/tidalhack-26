from __future__ import annotations

from typing import Any

UNKNOWN_NOTE = "Segmentation unavailable; ask user to confirm."
DEFAULT_CONFIDENCE = 0.82
LOW_LENGTH_THRESHOLD_PX = 120.0
LOW_MASK_FILL_THRESHOLD = 0.35
VERY_HIGH_BELLY_TUCK = 0.06


def _normalize(text: str) -> str:
    return " ".join(text.strip().lower().split())


def _find_mask_fill_ratio(ratios: dict[str, Any]) -> float | None:
    for key in (
        "mask_fill_bbox_ratio",
        "mask_fill_ratio",
        "mask_bbox_fill",
        "bbox_fill_ratio",
        "mask_fill",
    ):
        value = ratios.get(key)
        if value is None:
            continue
        try:
            return float(value)
        except (TypeError, ValueError):
            continue
    return None


def _plausible_weight_for_breed(
    *,
    priors: dict[str, dict[str, dict[str, Any]]] | None,
    species: str,
    breed_top1: str,
    weight_kg: float,
) -> bool | None:
    if priors is None:
        return None

    species_bucket = priors.get(_normalize(species))
    if not species_bucket:
        return None

    breed_prior = species_bucket.get(_normalize(breed_top1))
    if not breed_prior:
        return None

    min_weight = float(breed_prior["min_weight_kg"])
    max_weight = float(breed_prior["max_weight_kg"])
    return min_weight <= float(weight_kg) <= max_weight


def classify_bcs_bucket(
    *,
    ratios: dict[str, Any] | None,
    species: str,
    weight_kg: float | None = None,
    breed_top1: str | None = None,
    priors: dict[str, dict[str, dict[str, Any]]] | None = None,
) -> tuple[str, float, str]:
    if not ratios:
        return ("UNKNOWN", 0.50, UNKNOWN_NOTE)

    waist_to_chest = float(ratios.get("waist_to_chest", 0.0))
    belly_tuck = float(ratios.get("belly_tuck", 0.0))

    if waist_to_chest <= 0.70:
        bucket = "UNDERWEIGHT" if belly_tuck >= VERY_HIGH_BELLY_TUCK else "IDEAL"
    elif waist_to_chest <= 0.82:
        bucket = "OVERWEIGHT"
    else:
        bucket = "OBESE"

    confidence = DEFAULT_CONFIDENCE
    notes: list[str] = []

    length_px = float(ratios.get("length_px", 0.0))
    if length_px < LOW_LENGTH_THRESHOLD_PX:
        confidence -= 0.15
        notes.append("Low silhouette length; side/top view confidence reduced.")

    mask_fill_ratio = _find_mask_fill_ratio(ratios)
    if mask_fill_ratio is not None and mask_fill_ratio < LOW_MASK_FILL_THRESHOLD:
        confidence -= 0.15
        notes.append("Mask occupies little of bbox; side/top view confidence reduced.")

    if (
        weight_kg is not None
        and breed_top1
        and (plausible := _plausible_weight_for_breed(
            priors=priors,
            species=species,
            breed_top1=breed_top1,
            weight_kg=weight_kg,
        ))
        is False
    ):
        notes.append("Weight appears implausible for predicted breed range; confirm inputs.")

    confidence = max(0.50, min(0.95, confidence))
    return (bucket, float(confidence), " ".join(notes).strip())
