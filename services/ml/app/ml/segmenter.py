from __future__ import annotations

import os
import urllib.request
from pathlib import Path
from typing import Any

import numpy as np

MOBILE_SAM_WEIGHTS_URL = (
    "https://github.com/ChaoningZhang/MobileSAM/raw/master/weights/mobile_sam.pt"
)


class Segmenter:
    def __init__(
        self,
        cache_dir: str | os.PathLike[str] = ".cache",
        checkpoint_name: str = "mobile_sam.pt",
        weights_url: str = MOBILE_SAM_WEIGHTS_URL,
    ) -> None:
        self._cache_dir = Path(cache_dir)
        self._checkpoint_path = self._cache_dir / checkpoint_name
        self._weights_url = weights_url
        self._predictor: Any | None = None

    def _ensure_predictor(self) -> Any:
        if self._predictor is not None:
            return self._predictor

        try:
            import torch
            from mobile_sam import SamPredictor, sam_model_registry
        except Exception as exc:
            raise RuntimeError(
                "MobileSAM is required but not available. Install 'mobile-sam' and 'torch'."
            ) from exc

        self._cache_dir.mkdir(parents=True, exist_ok=True)
        if not self._checkpoint_path.exists():
            urllib.request.urlretrieve(self._weights_url, self._checkpoint_path)

        model = sam_model_registry["vit_t"](checkpoint=str(self._checkpoint_path))
        model.to(device="cpu")
        model.eval()

        with torch.no_grad():
            self._predictor = SamPredictor(model)
        return self._predictor

    @staticmethod
    def _normalize_bbox(
        bbox: list[int] | tuple[int, int, int, int] | None, width: int, height: int
    ) -> list[int]:
        if bbox is None:
            return [0, 0, width - 1, height - 1]

        if len(bbox) != 4:
            raise ValueError("bbox must be [x1, y1, x2, y2]")

        x1, y1, x2, y2 = [int(round(float(v))) for v in bbox]
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

    def segment(
        self,
        image_rgb: np.ndarray,
        bbox: list[int] | tuple[int, int, int, int] | None = None,
    ) -> np.ndarray:
        if not isinstance(image_rgb, np.ndarray):
            raise TypeError("image_rgb must be a numpy array")
        if image_rgb.ndim != 3 or image_rgb.shape[2] != 3:
            raise ValueError("image_rgb must have shape [H, W, 3]")
        if image_rgb.dtype != np.uint8:
            image_rgb = image_rgb.astype(np.uint8, copy=False)

        height, width = image_rgb.shape[:2]
        x1, y1, x2, y2 = self._normalize_bbox(bbox=bbox, width=width, height=height)

        predictor = self._ensure_predictor()
        predictor.set_image(image_rgb)
        masks, _, _ = predictor.predict(
            point_coords=None,
            point_labels=None,
            box=np.array([[x1, y1, x2, y2]], dtype=np.float32),
            multimask_output=False,
        )

        mask = (masks[0] > 0).astype(np.uint8) * 255
        return mask
