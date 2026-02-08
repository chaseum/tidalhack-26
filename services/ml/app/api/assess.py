from __future__ import annotations

import io
import json
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
from typing import Any, Literal, cast
from urllib.error import URLError

import numpy as np
from fastapi import APIRouter, HTTPException, Request
from openai import APIConnectionError, APITimeoutError
from PIL import Image, UnidentifiedImageError

from app.ml.bcs_rules import classify_bcs_bucket
from app.ml.breed_bbox import breed_bbox
from app.ml.breed_priors import load_priors
from app.ml.ratio_features import extract_ratio_features
from app.ml.segmenter import Segmenter
from app.schemas.assess import AssessMask, AssessRatios, AssessRequest, AssessResponse

router = APIRouter()
ASSESS_TIMEOUT_SECONDS = 8.0
_segmenter = Segmenter()
_executor = ThreadPoolExecutor(max_workers=2)


def _remaining_seconds(deadline: float) -> float:
    return max(0.0, deadline - time.monotonic())


def _ensure_time(deadline: float) -> None:
    if _remaining_seconds(deadline) <= 0:
        raise HTTPException(
            status_code=504,
            detail="Assessment timed out. Please try again.",
        )


def _mime_from_bytes(image_bytes: bytes, fallback: str | None = None) -> str:
    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            fmt = (img.format or "").upper()
    except UnidentifiedImageError:
        if fallback and fallback.startswith("image/"):
            return fallback
        return "application/octet-stream"
    if fmt == "JPEG":
        return "image/jpeg"
    if fmt == "PNG":
        return "image/png"
    if fmt == "WEBP":
        return "image/webp"
    if fmt == "GIF":
        return "image/gif"
    if fallback and fallback.startswith("image/"):
        return fallback
    return "application/octet-stream"


def _decode_rgb(image_bytes: bytes) -> np.ndarray:
    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            return np.array(img.convert("RGB"), dtype=np.uint8)
    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=400, detail="Could not decode image bytes.") from exc


def _fetch_image_bytes_and_mime(image_url: str, deadline: float) -> tuple[bytes, str]:
    timeout = max(0.1, _remaining_seconds(deadline))
    try:
        with urllib.request.urlopen(image_url, timeout=timeout) as response:
            image_bytes = response.read()
            header_mime = response.headers.get_content_type()
    except URLError as exc:
        raise HTTPException(status_code=400, detail="Unable to fetch image_url.") from exc
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image URL returned empty content.")

    mime = _mime_from_bytes(image_bytes, fallback=header_mime)
    if not mime.startswith("image/"):
        raise HTTPException(status_code=400, detail="URL must point to an image.")
    return image_bytes, mime


def _read_upload_bytes_and_mime(
    image_bytes: bytes,
    content_type: str | None,
) -> tuple[bytes, str]:
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    header_mime = (content_type or "").split(";", 1)[0].strip().lower() or None
    mime = _mime_from_bytes(image_bytes, fallback=header_mime)
    if not mime.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")
    return image_bytes, mime


def _run_with_budget(fn: Any, deadline: float, *args: Any, **kwargs: Any) -> Any:
    _ensure_time(deadline)
    future = _executor.submit(fn, *args, **kwargs)
    try:
        return future.result(timeout=max(0.1, _remaining_seconds(deadline)))
    except FutureTimeoutError as exc:
        raise HTTPException(
            status_code=504,
            detail="Assessment timed out. Please try again.",
        ) from exc


@router.post("/assess", response_model=AssessResponse)
async def assess(request: Request) -> AssessResponse:
    deadline = time.monotonic() + ASSESS_TIMEOUT_SECONDS
    payload: AssessRequest | None = None
    content_type = request.headers.get("content-type", "")

    if content_type.startswith("application/json"):
        try:
            raw_payload = await request.json()
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=400, detail="Invalid JSON request body.") from exc
        try:
            payload = AssessRequest.model_validate(raw_payload)
        except Exception as exc:
            raise HTTPException(status_code=422, detail="Invalid assess request payload.") from exc

        image_bytes, mime = _fetch_image_bytes_and_mime(
            image_url=str(payload.image_url),
            deadline=deadline,
        )
    else:
        upload_bytes = await request.body()
        image_bytes, mime = _read_upload_bytes_and_mime(
            image_bytes=upload_bytes,
            content_type=content_type,
        )

    image_rgb = _decode_rgb(image_bytes)
    _ensure_time(deadline)

    try:
        breed_result = _run_with_budget(
            breed_bbox,
            deadline,
            image_bytes,
            mime,
        )
    except HTTPException:
        raise
    except (APIConnectionError, APITimeoutError) as exc:
        raise HTTPException(
            status_code=502,
            detail="Vision service is temporarily unavailable.",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Vision service is temporarily unavailable.",
        ) from exc

    ratios_dict: dict[str, Any] | None = None
    mask_available = False
    bbox = breed_result["bbox"]
    try:
        mask = _run_with_budget(_segmenter.segment, deadline, image_rgb, bbox)
        if (
            isinstance(mask, np.ndarray)
            and mask.ndim == 2
            and mask.shape[:2] == image_rgb.shape[:2]
            and bool(np.any(mask > 0))
        ):
            ratios_dict = extract_ratio_features((mask > 0).astype(np.uint8))
            x1, y1, x2, y2 = bbox
            bbox_area = max(1, (x2 - x1) * (y2 - y1))
            mask_area = int(np.count_nonzero(mask > 0))
            ratios_dict["mask_fill_bbox_ratio"] = float(mask_area / bbox_area)
            mask_available = True
    except Exception:
        ratios_dict = None
        mask_available = False

    priors = None
    try:
        priors = load_priors()
    except Exception:
        priors = None

    bucket, confidence, notes = classify_bcs_bucket(
        ratios=ratios_dict,
        species=breed_result["species"],
        weight_kg=payload.meta.weight_kg if payload and payload.meta else None,
        breed_top1=breed_result["breed_top3"][0]["breed"],
        priors=priors,
    )

    ratios = AssessRatios(**ratios_dict) if ratios_dict else None
    return AssessResponse(
        species=breed_result["species"],
        breed_top3=breed_result["breed_top3"],
        mask=AssessMask(available=mask_available),
        ratios=ratios,
        bucket=cast(
            Literal["UNDERWEIGHT", "IDEAL", "OVERWEIGHT", "OBESE", "UNKNOWN"],
            bucket,
        ),
        confidence=confidence,
        notes=notes,
    )
