from __future__ import annotations

from typing import Any

import numpy as np

SLICE_FRACTIONS: tuple[float, ...] = (0.20, 0.35, 0.50, 0.65, 0.80)


def _slice_points(
    centered_points: np.ndarray,
    axis_coords: np.ndarray,
    target_u: float,
    band_half_width: float,
) -> np.ndarray:
    mask = np.abs(axis_coords - target_u) <= band_half_width
    if np.any(mask):
        return centered_points[mask]

    # If a thin/aliased mask has no points inside the nominal slice band,
    # use the closest points so slice widths remain stable.
    nearest_count = min(64, centered_points.shape[0])
    nearest_idx = np.argpartition(np.abs(axis_coords - target_u), nearest_count - 1)[
        :nearest_count
    ]
    return centered_points[nearest_idx]


def _pca_major_axis(points_xy: np.ndarray) -> np.ndarray:
    if points_xy.shape[0] < 2:
        return np.array([1.0, 0.0], dtype=np.float64)

    covariance = np.cov(points_xy, rowvar=False)
    eigenvalues, eigenvectors = np.linalg.eigh(covariance)
    major = eigenvectors[:, int(np.argmax(eigenvalues))]

    norm = float(np.linalg.norm(major))
    if norm <= 1e-8:
        return np.array([1.0, 0.0], dtype=np.float64)
    major = major / norm
    # Resolve sign ambiguity so body progression is stable across runs/images.
    if major[0] < 0 or (abs(float(major[0])) <= 1e-8 and major[1] < 0):
        major = -major
    return major


def extract_ratio_features(mask_uint8: np.ndarray) -> dict[str, Any]:
    """Compute geometric ratio features from a binary mask (0/1 values).

    Returns:
      - length_px: major-axis extent in pixels
      - waist_to_chest: width at 65% / width at 35%
      - width_profile: five widths sampled along major axis and normalized by length
      - belly_tuck: normalized lower-silhouette rise from 50% to 80% along major axis
    """
    if not isinstance(mask_uint8, np.ndarray):
        raise TypeError("mask_uint8 must be a numpy array")
    if mask_uint8.ndim != 2:
        raise ValueError("mask_uint8 must be a 2D array")

    ys, xs = np.where(mask_uint8 > 0)
    if xs.size == 0:
        return {
            "length_px": 0.0,
            "waist_to_chest": 0.0,
            "width_profile": [0.0] * len(SLICE_FRACTIONS),
            "belly_tuck": 0.0,
        }

    points_xy = np.column_stack((xs, ys)).astype(np.float64)
    centroid = points_xy.mean(axis=0)
    centered = points_xy - centroid

    major_axis = _pca_major_axis(points_xy)
    perp_axis = np.array([-major_axis[1], major_axis[0]], dtype=np.float64)

    u = centered @ major_axis
    v = centered @ perp_axis

    min_u = float(np.min(u))
    max_u = float(np.max(u))
    length_px = max(0.0, max_u - min_u)

    # Narrower for short masks, wider for long masks to make slices numerically stable.
    band_half_width = max(1.0, length_px * 0.015)

    widths_px: list[float] = []
    lower_heights: dict[float, float] = {}

    for frac in SLICE_FRACTIONS:
        target_u = min_u + frac * length_px
        slice_pts = _slice_points(centered, u, target_u, band_half_width)
        if slice_pts.size == 0:
            widths_px.append(0.0)
            lower_heights[frac] = float("nan")
            continue

        slice_v = slice_pts @ perp_axis
        width_px = float(np.max(slice_v) - np.min(slice_v))
        widths_px.append(max(0.0, width_px))

        # "Lower" silhouette in image coordinates is largest y.
        lower_heights[frac] = float(np.max(slice_pts[:, 1] + centroid[1]))

    chest_width = widths_px[1]
    waist_width = widths_px[3]
    waist_to_chest = 0.0 if chest_width <= 1e-8 else float(waist_width / chest_width)

    if length_px <= 1e-8:
        width_profile = [0.0] * len(widths_px)
    else:
        width_profile = [float(w / length_px) for w in widths_px]

    y50 = lower_heights.get(0.50, float("nan"))
    y80 = lower_heights.get(0.80, float("nan"))
    if np.isfinite(y50) and np.isfinite(y80) and length_px > 1e-8:
        belly_tuck = float((y50 - y80) / length_px)
    else:
        belly_tuck = 0.0

    return {
        "length_px": float(length_px),
        "waist_to_chest": float(waist_to_chest),
        "width_profile": width_profile,
        "belly_tuck": float(belly_tuck),
    }
