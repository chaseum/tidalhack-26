from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field, model_validator

from app.schemas.plan import Species


class PetFoodDefaults(BaseModel):
    kcal_per_g: float | None = Field(default=None, gt=0.0)
    kcal_per_cup: float | None = Field(default=None, gt=0.0)
    grams_per_cup: float | None = Field(default=None, gt=0.0)

    @model_validator(mode="after")
    def validate_food(self) -> "PetFoodDefaults":
        if self.kcal_per_g is not None:
            return self

        if self.kcal_per_cup is None and self.grams_per_cup is None:
            raise ValueError("Provide kcal_per_g or kcal_per_cup with grams_per_cup.")

        if self.kcal_per_cup is None or self.grams_per_cup is None:
            raise ValueError("kcal_per_cup and grams_per_cup must be provided together.")

        return self


class PetProfileUpsert(BaseModel):
    species: Species
    weight_kg: float = Field(gt=0.0)
    food: PetFoodDefaults


class PetRecord(BaseModel):
    pet_id: str
    species: Species | None = None
    weight_kg: float | None = None
    food: PetFoodDefaults | None = None
    last_assess: dict[str, Any] | None = None
    last_plan: dict[str, Any] | None = None
    updated_at: str
