from typing import Literal, Optional

from pydantic import AnyUrl, BaseModel, Field


class AssessRequestMeta(BaseModel):
    pet_id: Optional[str] = Field(default=None, min_length=1)
    species: Optional[str] = None
    breed_hint: Optional[str] = None
    weight_kg: Optional[float] = Field(default=None, gt=0.0)


class AssessRequest(BaseModel):
    image_url: AnyUrl
    meta: Optional[AssessRequestMeta] = None


class AssessMask(BaseModel):
    available: bool


class AssessBreedProb(BaseModel):
    breed: str
    p: float = Field(ge=0.0, le=1.0)


class AssessRatios(BaseModel):
    length_px: float
    waist_to_chest: float
    width_profile: list[float] = Field(min_length=5, max_length=5)
    belly_tuck: float


class AssessResponse(BaseModel):
    species: str
    breed_top3: list[AssessBreedProb] = Field(min_length=3, max_length=3)
    mask: AssessMask
    ratios: Optional[AssessRatios] = None
    bucket: Literal["UNDERWEIGHT", "IDEAL", "OVERWEIGHT", "OBESE", "UNKNOWN"]
    confidence: float = Field(ge=0.0, le=1.0)
    notes: str
