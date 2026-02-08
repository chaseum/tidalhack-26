from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.schemas.pet import PetProfileUpsert, PetRecord
from app.state.pet_store import pet_store

router = APIRouter()


@router.get("/pet/{pet_id}", response_model=PetRecord)
def get_pet(pet_id: str) -> PetRecord:
    record = pet_store.get(pet_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Pet profile not found.")
    return PetRecord.model_validate(record)


@router.post("/pet/{pet_id}", response_model=PetRecord)
def upsert_pet_profile(pet_id: str, payload: PetProfileUpsert) -> PetRecord:
    record = pet_store.upsert_profile(
        pet_id,
        species=payload.species,
        weight_kg=payload.weight_kg,
        food=payload.food.model_dump(),
    )
    return PetRecord.model_validate(record)
