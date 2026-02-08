from fastapi import APIRouter

from app.schemas.assess import (
    AssessMask,
    AssessRatios,
    AssessRequest,
    AssessResponse,
)

router = APIRouter()


@router.post("/assess", response_model=AssessResponse)
def assess(payload: AssessRequest) -> AssessResponse:
    _ = payload
    return AssessResponse(
        species="dog",
        breed_top3=["labrador_retriever", "golden_retriever", "mixed"],
        mask=AssessMask(available=True),
        ratios=AssessRatios(environmental=0.62, social=0.71, governance=0.67),
        bucket="medium",
        confidence=0.84,
        notes=["deterministic stub response"],
    )
