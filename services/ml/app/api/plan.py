from fastapi import APIRouter

from app.schemas.plan import Goal, PlanRequest, PlanResponse
from app.state.pet_store import pet_store

router = APIRouter()

DISCLAIMER = (
    "Educational estimate only. Confirm your pet's feeding plan with a licensed veterinarian."
)

MULTIPLIER_TABLE: dict[Goal, dict[str, float]] = {
    "LOSE": {
        "LOW": 1.0,
        "MODERATE": 1.1,
        "HIGH": 1.2,
    },
    "MAINTAIN": {
        "LOW": 1.2,
        "MODERATE": 1.4,
        "HIGH": 1.6,
    },
    "GAIN": {
        "LOW": 1.5,
        "MODERATE": 1.7,
        "HIGH": 1.9,
    },
}


def _normalize_kcal_per_g(payload: PlanRequest) -> float:
    if payload.food.kcal_per_g is not None:
        return payload.food.kcal_per_g

    # Request validation guarantees these are present together in this branch.
    kcal_per_cup = payload.food.kcal_per_cup
    grams_per_cup = payload.food.grams_per_cup
    if kcal_per_cup is None or grams_per_cup is None:
        raise ValueError("Invalid food payload.")
    return kcal_per_cup / grams_per_cup


@router.post("/plan", response_model=PlanResponse)
def plan(payload: PlanRequest) -> PlanResponse:
    kcal_per_g = _normalize_kcal_per_g(payload)
    rer = 70 * (payload.weight_kg**0.75)
    multiplier = MULTIPLIER_TABLE[payload.goal][payload.activity]
    daily_calories = round(rer * multiplier)
    grams_per_day = round(daily_calories / kcal_per_g)

    response = PlanResponse(
        pet_id=payload.pet_id,
        species=payload.species,
        weight_kg=payload.weight_kg,
        bucket=payload.bucket,
        activity=payload.activity,
        goal=payload.goal,
        kcal_per_g=kcal_per_g,
        rer=rer,
        multiplier=multiplier,
        daily_calories=daily_calories,
        grams_per_day=grams_per_day,
        disclaimer=DISCLAIMER,
    )
    pet_store.save_last_plan(payload.pet_id, response.model_dump())
    return response
