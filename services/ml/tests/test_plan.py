from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _base_payload() -> dict:
    return {
        "pet_id": "pet_123",
        "species": "dog",
        "weight_kg": 10.0,
        "bucket": "IDEAL",
        "activity": "MODERATE",
        "goal": "MAINTAIN",
    }


def test_plan_happy_path_with_kcal_per_g() -> None:
    payload = {
        **_base_payload(),
        "food": {"kcal_per_g": 3.5},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["kcal_per_g"] == 3.5
    assert body["multiplier"] == 1.4
    assert body["daily_calories"] == round(body["rer"] * body["multiplier"])
    assert body["grams_per_day"] == round(body["daily_calories"] / body["kcal_per_g"])
    assert "veterinarian" in body["disclaimer"].lower()


def test_plan_happy_path_with_kcal_per_cup_normalization() -> None:
    payload = {
        **_base_payload(),
        "food": {"kcal_per_cup": 350.0, "grams_per_cup": 100.0},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["kcal_per_g"] == 3.5


def test_plan_rejects_missing_food_energy_fields() -> None:
    payload = {
        **_base_payload(),
        "food": {},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 422


def test_plan_rejects_kcal_per_cup_without_grams_per_cup() -> None:
    payload = {
        **_base_payload(),
        "food": {"kcal_per_cup": 320.0},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 422


def test_plan_rejects_invalid_species_enum() -> None:
    payload = {
        **_base_payload(),
        "species": "rabbit",
        "food": {"kcal_per_g": 3.2},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 422


def test_plan_calculation_rounding_with_goal_activity_multiplier() -> None:
    payload = {
        **_base_payload(),
        "weight_kg": 8.0,
        "activity": "HIGH",
        "goal": "GAIN",
        "food": {"kcal_per_g": 4.0},
    }

    response = client.post("/plan", json=payload)

    assert response.status_code == 200
    body = response.json()
    expected_rer = 70 * (8.0**0.75)
    expected_multiplier = 1.9
    expected_daily_calories = round(expected_rer * expected_multiplier)
    expected_grams = round(expected_daily_calories / 4.0)

    assert body["rer"] == expected_rer
    assert body["multiplier"] == expected_multiplier
    assert body["daily_calories"] == expected_daily_calories
    assert body["grams_per_day"] == expected_grams
