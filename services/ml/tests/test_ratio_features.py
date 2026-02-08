import numpy as np

from app.ml.ratio_features import extract_ratio_features


def _make_constant_width_mask(
    *,
    h: int = 120,
    w: int = 220,
    x_start: int = 20,
    x_end: int = 190,
    center_y: int = 60,
    half_width: int = 20,
) -> np.ndarray:
    mask = np.zeros((h, w), dtype=np.uint8)
    for x in range(x_start, x_end + 1):
        top = max(0, center_y - half_width)
        bottom = min(h - 1, center_y + half_width)
        mask[top : bottom + 1, x] = 1
    return mask


def _make_tapered_tuck_mask(
    *,
    h: int = 140,
    w: int = 240,
    x_start: int = 20,
    x_end: int = 210,
    center_y: float = 72.0,
) -> np.ndarray:
    mask = np.zeros((h, w), dtype=np.uint8)
    span = float(max(1, x_end - x_start))

    for x in range(x_start, x_end + 1):
        t = (x - x_start) / span

        # Wider chest and narrower waist/rear.
        half_width = 24.0 - 10.0 * t

        # Tuck the belly up toward the rear: lower edge rises after midpoint.
        tuck = 0.0 if t <= 0.5 else 12.0 * (t - 0.5) / 0.5

        top = int(round(center_y - half_width))
        bottom = int(round(center_y + half_width - tuck))

        top = max(0, min(h - 1, top))
        bottom = max(0, min(h - 1, bottom))
        if bottom >= top:
            mask[top : bottom + 1, x] = 1

    return mask


def test_extract_ratio_features_empty_mask() -> None:
    mask = np.zeros((32, 32), dtype=np.uint8)
    features = extract_ratio_features(mask)

    assert features["length_px"] == 0.0
    assert features["waist_to_chest"] == 0.0
    assert features["width_profile"] == [0.0, 0.0, 0.0, 0.0, 0.0]
    assert features["belly_tuck"] == 0.0


def test_extract_ratio_features_constant_width_shape() -> None:
    mask = _make_constant_width_mask()
    features = extract_ratio_features(mask)

    assert features["length_px"] > 150.0
    assert abs(features["waist_to_chest"] - 1.0) < 0.08
    assert len(features["width_profile"]) == 5
    assert max(features["width_profile"]) - min(features["width_profile"]) < 0.08
    assert abs(features["belly_tuck"]) < 0.03


def test_extract_ratio_features_tapered_with_belly_tuck() -> None:
    mask = _make_tapered_tuck_mask()
    features = extract_ratio_features(mask)

    assert features["length_px"] > 170.0
    assert features["waist_to_chest"] < 0.90
    assert len(features["width_profile"]) == 5
    assert features["width_profile"][1] > features["width_profile"][3]
    assert features["belly_tuck"] > 0.02
