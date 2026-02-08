import io
import re
from typing import Any, Literal, TypedDict

from PIL import Image

from .featherless_vision_json import vision_json


class BreedProb(TypedDict):
    breed: str
    p: float


class BreedBboxResult(TypedDict):
    species: Literal["dog", "cat"]
    breed_top3: list[BreedProb]
    bbox: list[int]


_PROMPT = (
    "Classify the main pet in the image. "
    "Return JSON with: "
    'species ("dog" or "cat"), '
    "breed_top3 (exactly 3 items, each {breed: snake_case string, p: 0..1}), "
    "bbox ([x1,y1,x2,y2] integer pixels in original image, tight around pet body only, not background)."
)
_SNAKE_CASE_RE = re.compile(r"^[a-z0-9]+(?:_[a-z0-9]+)*$")


def _image_size(image_bytes: bytes) -> tuple[int, int]:
    with Image.open(io.BytesIO(image_bytes)) as img:
        return img.size


def _normalize_species(value: Any) -> Literal["dog", "cat"]:
    species = str(value).strip().lower()
    if species not in {"dog", "cat"}:
        raise ValueError("species must be 'dog' or 'cat'")
    return species  # type: ignore[return-value]


def _normalize_breed(value: Any) -> str:
    breed = str(value).strip().lower().replace("-", " ")
    breed = re.sub(r"[^a-z0-9\s]", "", breed)
    breed = "_".join(part for part in breed.split() if part)
    if not breed or not _SNAKE_CASE_RE.match(breed):
        raise ValueError("breed must be snake_case")
    return breed


def _normalize_prob(value: Any) -> float:
    prob = float(value)
    if prob < 0.0:
        return 0.0
    if prob > 1.0:
        return 1.0
    return prob


def _normalize_breed_top3(value: Any) -> list[BreedProb]:
    if not isinstance(value, list) or len(value) != 3:
        raise ValueError("breed_top3 must have exactly 3 items")

    out: list[BreedProb] = []
    for item in value:
        if not isinstance(item, dict):
            raise ValueError("each breed_top3 item must be an object")
        out.append(
            {
                "breed": _normalize_breed(item.get("breed")),
                "p": _normalize_prob(item.get("p")),
            }
        )
    return out


def _normalize_bbox(value: Any, width: int, height: int) -> list[int]:
    if not isinstance(value, list) or len(value) != 4:
        raise ValueError("bbox must be [x1,y1,x2,y2]")

    x1, y1, x2, y2 = [int(round(float(v))) for v in value]

    x1 = max(0, min(x1, width - 1))
    y1 = max(0, min(y1, height - 1))
    x2 = max(0, min(x2, width - 1))
    y2 = max(0, min(y2, height - 1))

    if x2 <= x1:
        if x1 < width - 1:
            x2 = x1 + 1
        else:
            x1 = max(0, x1 - 1)

    if y2 <= y1:
        if y1 < height - 1:
            y2 = y1 + 1
        else:
            y1 = max(0, y1 - 1)

    return [x1, y1, x2, y2]


def breed_bbox(image_bytes: bytes, mime: str) -> BreedBboxResult:
    width, height = _image_size(image_bytes)
    raw = vision_json(image_bytes=image_bytes, mime=mime, prompt_text=_PROMPT)

    return {
        "species": _normalize_species(raw.get("species")),
        "breed_top3": _normalize_breed_top3(raw.get("breed_top3")),
        "bbox": _normalize_bbox(raw.get("bbox"), width=width, height=height),
    }
