from fastapi.testclient import TestClient
from openai import APITimeoutError

from app.main import app

client = TestClient(app)


def test_chat_returns_model_json_payload(monkeypatch) -> None:
    def fake_text_chat(*, messages, timeout_seconds):
        _ = messages
        assert timeout_seconds == 8.0
        return (
            '{"reply":"Track appetite and water intake today. If breathing worsens, '
            'go to vet ER now.","quick_actions":["Log appetite this morning and evening.",'
            '"Check breathing rate while resting.","Call your vet today for guidance."]}'
        )

    monkeypatch.setattr("app.api.chat.text_chat", fake_text_chat)

    response = client.post("/chat", json={"message": "my cat seems off today"})

    assert response.status_code == 200
    assert response.json() == {
        "reply": (
            "Track appetite and water intake today. If breathing worsens, go to vet ER now."
        ),
        "quick_actions": [
            "Log appetite this morning and evening.",
            "Check breathing rate while resting.",
            "Call your vet today for guidance.",
        ],
    }


def test_chat_falls_back_when_model_errors(monkeypatch) -> None:
    def fake_text_chat(*, messages, timeout_seconds):
        _ = messages
        _ = timeout_seconds
        raise APITimeoutError(request=None)

    monkeypatch.setattr("app.api.chat.text_chat", fake_text_chat)

    response = client.post("/chat", json={"message": "help"})

    assert response.status_code == 200
    body = response.json()
    assert isinstance(body["reply"], str) and body["reply"]
    assert isinstance(body["quick_actions"], list) and len(body["quick_actions"]) >= 1


def test_chat_rejects_empty_message() -> None:
    response = client.post("/chat", json={"message": ""})
    assert response.status_code == 422
