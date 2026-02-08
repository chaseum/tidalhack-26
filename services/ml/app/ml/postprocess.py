from __future__ import annotations

from typing import Iterable, Literal

import torch

BreedProb = dict[str, float | str]

DEFAULT_CAT_BREEDS: set[str] = {
    "abyssinian",
    "bengal",
    "birman",
    "bombay",
    "british_shorthair",
    "egyptian_mau",
    "maine_coon",
    "persian",
    "ragdoll",
    "russian_blue",
    "siamese",
    "sphynx",
}


def _normalize_breed_name(label: str) -> str:
    return "_".join(
        part for part in label.strip().lower().replace("-", "_").split("_") if part
    )


def topk_breed_probs(
    logits: torch.Tensor,
    *,
    labels: list[str],
    top_k: int = 3,
) -> list[BreedProb]:
    if logits.ndim != 1:
        raise ValueError("Expected 1D logits tensor.")
    if len(labels) != int(logits.shape[0]):
        raise ValueError("labels length must match logits size.")

    safe_k = min(max(1, top_k), logits.shape[0])
    probs = torch.softmax(logits, dim=0)
    top_probs, top_indices = torch.topk(probs, k=safe_k)

    output: list[BreedProb] = []
    for idx, prob in zip(top_indices.tolist(), top_probs.tolist(), strict=True):
        output.append({"breed": _normalize_breed_name(labels[idx]), "p": float(prob)})

    if output:
        renorm = sum(float(item["p"]) for item in output)
        if renorm > 1e-8:
            for item in output:
                item["p"] = float(float(item["p"]) / renorm)

    while len(output) < 3:
        output.append({"breed": "mixed", "p": 0.0})

    return output[:3]


def infer_species(
    breed_top3: list[BreedProb],
    *,
    cat_breeds: Iterable[str] = DEFAULT_CAT_BREEDS,
) -> Literal["dog", "cat"]:
    cat_set = {_normalize_breed_name(name) for name in cat_breeds}
    cat_score = 0.0
    dog_score = 0.0

    for item in breed_top3:
        breed = _normalize_breed_name(str(item["breed"]))
        prob = float(item["p"])
        if breed in cat_set:
            cat_score += prob
        else:
            dog_score += prob

    return "cat" if cat_score >= dog_score else "dog"
