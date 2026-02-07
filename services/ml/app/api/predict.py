from fastapi import APIRouter

from app.schemas.predict import PredictRequest, PredictResponse, PredictScores

router = APIRouter()


@router.post("/predict", response_model=PredictResponse)
def predict(payload: PredictRequest) -> PredictResponse:
    _ = payload  # request is validated by Pydantic; response is deterministic stub
    return PredictResponse(
        scores=PredictScores(
            environmental=0.7,
            social=0.5,
            governance=0.8,
        ),
        confidence=0.82,
    )
