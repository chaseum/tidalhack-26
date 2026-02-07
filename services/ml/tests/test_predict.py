from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_predict_returns_deterministic_schema() -> None:
    payload = {"image_url": "https://example.com/image1.jpg"}
    response = client.post("/predict", json=payload)

    assert response.status_code == 200
    assert response.json() == {
        "scores": {
            "environmental": 0.7,
            "social": 0.5,
            "governance": 0.8,
        },
        "confidence": 0.82,
    }
