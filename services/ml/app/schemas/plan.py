from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, model_validator

Species = Literal["dog", "cat"]
Bucket = Literal["UNDERWEIGHT", "IDEAL", "OVERWEIGHT", "OBESE", "UNKNOWN"]
Activity = Literal["LOW", "MODERATE", "HIGH"]
Goal = Literal["LOSE", "MAINTAIN", "GAIN"]


class PlanFood(BaseModel):
    kcal_per_g: float | None = Field(default=None, gt=0.0)
    kcal_per_cup: float | None = Field(default=None, gt=0.0)
    grams_per_cup: float | None = Field(default=None, gt=0.0)

    @model_validator(mode="after")
    def validate_food(self) -> "PlanFood":
        if self.kcal_per_g is not None:
            return self

        if self.kcal_per_cup is None and self.grams_per_cup is None:
            raise ValueError("Provide kcal_per_g or kcal_per_cup with grams_per_cup.")

        if self.kcal_per_cup is None or self.grams_per_cup is None:
            raise ValueError("kcal_per_cup and grams_per_cup must be provided together.")

        return self


class PlanRequest(BaseModel):
    pet_id: str = Field(min_length=1)
    species: Species
    weight_kg: float = Field(gt=0.0)
    bucket: Bucket
    activity: Activity
    goal: Goal
    food: PlanFood


class PlanResponse(BaseModel):
    pet_id: str
    species: Species
    weight_kg: float
    bucket: Bucket
    activity: Activity
    goal: Goal
    kcal_per_g: float = Field(gt=0.0)
    rer: float = Field(gt=0.0)
    multiplier: float = Field(gt=0.0)
    daily_calories: int = Field(gt=0)
    grams_per_day: int = Field(gt=0)
    disclaimer: str
