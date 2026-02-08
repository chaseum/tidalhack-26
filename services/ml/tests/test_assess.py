import numpy as np
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _stub_fetch(_image_url: str, _deadline: float) -> tuple[bytes, str]:
    return (b"fake-image-bytes", "image/jpeg")


def _stub_decode_rgb(_image_bytes: bytes) -> np.ndarray:
    return np.zeros((16, 16, 3), dtype=np.uint8)


def test_assess_happy_path(monkeypatch) -> None:
    from app.api import assess as assess_api

    monkeypatch.setattr(assess_api, "_fetch_image_bytes_and_mime", _stub_fetch)
    monkeypatch.setattr(assess_api, "_decode_rgb", _stub_decode_rgb)
    monkeypatch.setattr(
        assess_api,
        "breed_bbox",
        lambda image_bytes, mime: {
            "species": "dog",
            "breed_top3": [
                {"breed": "labrador_retriever", "p": 0.62},
                {"breed": "golden_retriever", "p": 0.21},
                {"breed": "mixed", "p": 0.17},
            ],
            "bbox": [2, 2, 14, 14],
        },
    )
    monkeypatch.setattr(
        assess_api._segmenter,
        "segment",
        lambda image_rgb, bbox: np.pad(
            np.ones((8, 8), dtype=np.uint8),
            pad_width=((4, 4), (4, 4)),
            mode="constant",
            constant_values=0,
        ),
    )
    monkeypatch.setattr(
        assess_api,
        "extract_ratio_features",
        lambda mask_uint8: {
            "length_px": 180.0,
            "waist_to_chest": 0.78,
            "width_profile": [0.90, 0.88, 0.85, 0.80, 0.78],
            "belly_tuck": 0.03,
        },
    )
    monkeypatch.setattr(assess_api, "load_priors", lambda: None)

    response = client.post(
        "/assess",
        json={"image_url": "https://example.com/pet.jpg"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["species"] == "dog"
    assert len(body["breed_top3"]) == 3
    assert body["mask"] == {"available": True}
    assert body["ratios"]["waist_to_chest"] == 0.78
    assert body["bucket"] == "OVERWEIGHT"


def test_assess_segmentation_failure_returns_unknown(monkeypatch) -> None:
    from app.api import assess as assess_api

    monkeypatch.setattr(assess_api, "_fetch_image_bytes_and_mime", _stub_fetch)
    monkeypatch.setattr(assess_api, "_decode_rgb", _stub_decode_rgb)
    monkeypatch.setattr(
        assess_api,
        "breed_bbox",
        lambda image_bytes, mime: {
            "species": "cat",
            "breed_top3": [
                {"breed": "siamese", "p": 0.80},
                {"breed": "ragdoll", "p": 0.15},
                {"breed": "mixed", "p": 0.05},
            ],
            "bbox": [1, 1, 12, 12],
        },
    )
    monkeypatch.setattr(
        assess_api._segmenter,
        "segment",
        lambda image_rgb, bbox: (_ for _ in ()).throw(RuntimeError("seg failed")),
    )

    response = client.post(
        "/assess",
        json={"image_url": "https://example.com/pet.jpg"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["mask"] == {"available": False}
    assert body["ratios"] is None
    assert body["bucket"] == "UNKNOWN"


def test_assess_vision_failure_returns_502(monkeypatch) -> None:
    from app.api import assess as assess_api

    monkeypatch.setattr(assess_api, "_fetch_image_bytes_and_mime", _stub_fetch)
    monkeypatch.setattr(assess_api, "_decode_rgb", _stub_decode_rgb)
    monkeypatch.setattr(
        assess_api,
        "breed_bbox",
        lambda image_bytes, mime: (_ for _ in ()).throw(RuntimeError("vision down")),
    )

    response = client.post(
        "/assess",
        json={"image_url": "https://example.com/pet.jpg"},
    )

    assert response.status_code == 502
    assert response.json() == {"detail": "Vision service is temporarily unavailable."}


def test_assess_accepts_multipart_form(monkeypatch) -> None:
    from app.api import assess as assess_api

    monkeypatch.setattr(assess_api, "_decode_rgb", _stub_decode_rgb)
    monkeypatch.setattr(
        assess_api,
        "breed_bbox",
        lambda image_bytes, mime: {
            "species": "dog",
            "breed_top3": [
                {"breed": "labrador_retriever", "p": 0.62},
                {"breed": "golden_retriever", "p": 0.21},
                {"breed": "mixed", "p": 0.17},
            ],
            "bbox": [2, 2, 14, 14],
        },
    )
    monkeypatch.setattr(
        assess_api._segmenter,
        "segment",
        lambda image_rgb, bbox: np.pad(
            np.ones((8, 8), dtype=np.uint8),
            pad_width=((4, 4), (4, 4)),
            mode="constant",
            constant_values=0,
        ),
    )
    monkeypatch.setattr(
        assess_api,
        "extract_ratio_features",
        lambda mask_uint8: {
            "length_px": 180.0,
            "waist_to_chest": 0.78,
            "width_profile": [0.90, 0.88, 0.85, 0.80, 0.78],
            "belly_tuck": 0.03,
        },
    )
    monkeypatch.setattr(assess_api, "load_priors", lambda: None)

    response = client.post(
        "/assess",
        data={
            "species": "dog",
            "breed_hint": "labrador",
            "weight_kg": "24.5",
        },
        files={"image": ("pet.jpg", b"fake-image-bytes", "image/jpeg")},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["species"] == "dog"
    assert body["mask"] == {"available": True}
