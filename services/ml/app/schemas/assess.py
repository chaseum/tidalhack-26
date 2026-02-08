from typing import Literal, Optional

from pydantic import AnyUrl, BaseModel, Field


class AssessRequestMeta(BaseModel):
    species: Optional[str] = None
    breed_hint: Optional[str] = None
    weight_kg: Optional[float] = Field(default=None, gt=0.0)


class AssessRequest(BaseModel):
    image_url: AnyUrl
    meta: Optional[AssessRequestMeta] = None


class AssessMask(BaseModel):
    available: bool


class AssessRatios(BaseModel):
    environmental: float
    social: float
    governance: float


class AssessResponse(BaseModel):
    species: str
    breed_top3: list[str] = Field(min_length=3, max_length=3)
    mask: AssessMask
    ratios: AssessRatios
    bucket: Literal["low", "medium", "high"]
    confidence: float = Field(ge=0.0, le=1.0)
    notes: list[str]
