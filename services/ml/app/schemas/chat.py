from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    session_id: str | None = None


class ChatResponse(BaseModel):
    reply: str = Field(min_length=1)
    quick_actions: list[str] = Field(min_length=1)
