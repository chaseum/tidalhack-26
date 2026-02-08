import numpy as np
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _stub_decode_rgb(_image_bytes: bytes) -> np.ndarray:
    return np.zeros((16, 16, 3), dtype=np.uint8)


def test_pet_profile_upsert_and_get() -> None:
    pet_id = "demo_profile_pet"
    payload = {
        "species": "dog",
        "weight_kg": 18.4,
        "food": {"kcal_per_g": 3.4},
    }

    upsert_response = client.post(f"/pet/{pet_id}", json=payload)
    assert upsert_response.status_code == 200
    upsert_body = upsert_response.json()
    assert upsert_body["pet_id"] == pet_id
    assert upsert_body["species"] == "dog"
    assert upsert_body["weight_kg"] == 18.4
    assert upsert_body["food"]["kcal_per_g"] == 3.4
    assert isinstance(upsert_body["updated_at"], str)

    get_response = client.get(f"/pet/{pet_id}")
    assert get_response.status_code == 200
    get_body = get_response.json()
    assert get_body["pet_id"] == pet_id
    assert get_body["species"] == "dog"
    assert get_body["last_assess"] is None
    assert get_body["last_plan"] is None


def test_plan_persists_last_plan() -> None:
    pet_id = "persist_plan_pet"
    payload = {
        "pet_id": pet_id,
        "species": "cat",
        "weight_kg": 4.8,
        "bucket": "IDEAL",
        "activity": "LOW",
        "goal": "MAINTAIN",
        "food": {"kcal_per_g": 3.9},
    }

    plan_response = client.post("/plan", json=payload)
    assert plan_response.status_code == 200
    plan_body = plan_response.json()

    pet_response = client.get(f"/pet/{pet_id}")
    assert pet_response.status_code == 200
    pet_body = pet_response.json()
    assert pet_body["last_plan"] is not None
    assert pet_body["last_plan"]["pet_id"] == pet_id
    assert pet_body["last_plan"]["daily_calories"] == plan_body["daily_calories"]


def test_assess_persists_last_assess_with_pet_id(monkeypatch) -> None:
    from app.api import assess as assess_api

    pet_id = "persist_assess_pet"

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
        data={"request": '{"meta":{"pet_id":"persist_assess_pet"}}'},
        files={"image": ("pet.jpg", b"fake-image-bytes", "image/jpeg")},
    )
    assert response.status_code == 200

    pet_response = client.get(f"/pet/{pet_id}")
    assert pet_response.status_code == 200
    pet_body = pet_response.json()
    assert pet_body["last_assess"] is not None
    assert pet_body["last_assess"]["species"] == "dog"
    assert pet_body["last_plan"] is None
