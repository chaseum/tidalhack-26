from pydantic import AnyUrl, BaseModel, Field


class PredictRequest(BaseModel):
    image_url: AnyUrl


class PredictScores(BaseModel):
    environmental: float
    social: float
    governance: float


class PredictResponse(BaseModel):
    scores: PredictScores
    confidence: float = Field(ge=0.0, le=1.0)
