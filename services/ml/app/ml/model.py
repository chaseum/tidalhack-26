from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import torch
from torch import nn

from .postprocess import DEFAULT_CAT_BREEDS, infer_species, topk_breed_probs
from .preprocess import preprocess_image

MODEL_FILE_ENV = "OXFORD_PET_MODEL_PATH"
DEFAULT_MODEL_PATH = (
    Path(__file__).resolve().parents[2] / "data" / "models" / "oxford_pet_breed.pt"
)


class ConvBlock(nn.Module):
    def __init__(self, in_ch: int, out_ch: int, *, pool: bool = True) -> None:
        super().__init__()
        layers: list[nn.Module] = [
            nn.Conv2d(in_ch, out_ch, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
        ]
        if pool:
            layers.append(nn.MaxPool2d(kernel_size=2, stride=2))
        self.block = nn.Sequential(*layers)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.block(x)


class BreedNet(nn.Module):
    """Compact CNN for Oxford-IIIT Pet 37-class breed classification."""

    def __init__(self, num_classes: int) -> None:
        super().__init__()
        self.features = nn.Sequential(
            ConvBlock(3, 32),
            ConvBlock(32, 64),
            ConvBlock(64, 128),
            ConvBlock(128, 256),
        )
        self.classifier = nn.Sequential(
            nn.AdaptiveAvgPool2d((1, 1)),
            nn.Flatten(),
            nn.Dropout(p=0.25),
            nn.Linear(256, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.classifier(self.features(x))


@dataclass(frozen=True)
class ModelArtifacts:
    model: BreedNet
    labels: list[str]
    image_size: int
    cat_breeds: set[str]
    metadata: dict[str, Any]


@dataclass(frozen=True)
class BreedModelOutput:
    species: str
    breed_top3: list[dict[str, Any]]


def resolve_checkpoint_path(path: str | os.PathLike[str] | None = None) -> Path:
    if path is not None:
        return Path(path)
    configured = os.getenv(MODEL_FILE_ENV)
    return Path(configured) if configured else DEFAULT_MODEL_PATH


def save_model_checkpoint(
    *,
    checkpoint_path: str | os.PathLike[str],
    model: BreedNet,
    labels: list[str],
    image_size: int,
    cat_breeds: set[str],
    metadata: dict[str, Any] | None = None,
) -> None:
    path = Path(checkpoint_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "model_state_dict": model.state_dict(),
        "labels": labels,
        "image_size": int(image_size),
        "cat_breeds": sorted(cat_breeds),
        "metadata": metadata or {},
    }
    torch.save(payload, path)


def load_model_checkpoint(
    checkpoint_path: str | os.PathLike[str],
    *,
    map_location: str | torch.device = "cpu",
) -> ModelArtifacts:
    raw = torch.load(Path(checkpoint_path), map_location=map_location)
    labels = [str(label) for label in raw["labels"]]
    model = BreedNet(num_classes=len(labels))
    model.load_state_dict(raw["model_state_dict"])
    model.eval()

    image_size = int(raw.get("image_size", 224))
    cat_breeds = {str(item).strip().lower() for item in raw.get("cat_breeds", [])}
    if not cat_breeds:
        cat_breeds = set(DEFAULT_CAT_BREEDS)

    metadata = raw.get("metadata", {})
    if not isinstance(metadata, dict):
        metadata = {}

    return ModelArtifacts(
        model=model,
        labels=labels,
        image_size=image_size,
        cat_breeds=cat_breeds,
        metadata=metadata,
    )


class OxfordPetBreedClassifier:
    """Loads a trained Oxford-IIIT Pet checkpoint and predicts top-3 breeds."""

    def __init__(
        self,
        checkpoint_path: str | os.PathLike[str] | None = None,
        *,
        device: str | torch.device = "cpu",
    ) -> None:
        self._checkpoint_path = resolve_checkpoint_path(checkpoint_path)
        self._device = torch.device(device)
        self._artifacts: ModelArtifacts | None = None

    def checkpoint_exists(self) -> bool:
        return self._checkpoint_path.exists()

    @property
    def checkpoint_path(self) -> Path:
        return self._checkpoint_path

    def _ensure_loaded(self) -> ModelArtifacts:
        if self._artifacts is not None:
            return self._artifacts

        if not self._checkpoint_path.exists():
            raise FileNotFoundError(
                "Oxford-IIIT Pet checkpoint not found. "
                f"Expected: {self._checkpoint_path}"
            )

        artifacts = load_model_checkpoint(
            self._checkpoint_path,
            map_location=self._device,
        )
        artifacts.model.to(self._device)
        artifacts.model.eval()
        self._artifacts = artifacts
        return artifacts

    @torch.inference_mode()
    def predict(self, image: bytes | Any, *, top_k: int = 3) -> BreedModelOutput:
        artifacts = self._ensure_loaded()
        tensor = preprocess_image(
            image,
            image_size=artifacts.image_size,
            train=False,
        ).unsqueeze(0)
        tensor = tensor.to(self._device)

        logits = artifacts.model(tensor)[0].detach().cpu()
        breed_top3 = topk_breed_probs(logits, labels=artifacts.labels, top_k=top_k)
        species = infer_species(breed_top3, cat_breeds=artifacts.cat_breeds)
        return BreedModelOutput(species=species, breed_top3=breed_top3)
