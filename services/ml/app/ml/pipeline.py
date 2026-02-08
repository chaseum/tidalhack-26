from __future__ import annotations

import argparse
import random
import tarfile
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import re
from urllib.error import URLError

import numpy as np
import torch
from PIL import Image
from torch import nn
from torch.utils.data import DataLoader, Dataset

from .model import (
    OxfordPetBreedClassifier,
    BreedNet,
    save_model_checkpoint,
    resolve_checkpoint_path,
)
from .postprocess import DEFAULT_CAT_BREEDS
from .preprocess import collate_tensor_batch, preprocess_image

OXFORD_PET_IMAGES_URL = "https://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz"
OXFORD_PET_ANNOTATIONS_URL = (
    "https://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz"
)


def _services_ml_root() -> Path:
    # services/ml/app/ml/pipeline.py -> services/ml
    return Path(__file__).resolve().parents[2]


def default_dataset_dir() -> Path:
    return _services_ml_root() / "data" / "oxford_iiit_pet"


def _safe_extract(tar_path: Path, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    with tarfile.open(tar_path, mode="r:gz") as archive:
        for member in archive.getmembers():
            target = out_dir / member.name
            if not str(target.resolve()).startswith(str(out_dir.resolve())):
                raise ValueError(f"Unsafe tar member path: {member.name}")
        archive.extractall(path=out_dir)


def _download(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(url) as response, destination.open("wb") as out_file:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                out_file.write(chunk)
    except (URLError, OSError) as exc:
        raise RuntimeError(
            f"Failed to download dataset archive from {url}. "
            f"Check network access or place the archive at {destination}."
        ) from exc


def download_oxford_iiit_pet(
    *,
    dataset_dir: Path,
    force_download: bool = False,
) -> Path:
    dataset_dir.mkdir(parents=True, exist_ok=True)
    archives_dir = dataset_dir / "archives"
    archives_dir.mkdir(parents=True, exist_ok=True)

    images_archive = archives_dir / "images.tar.gz"
    annotations_archive = archives_dir / "annotations.tar.gz"

    if force_download or not images_archive.exists():
        _download(OXFORD_PET_IMAGES_URL, images_archive)
    if force_download or not annotations_archive.exists():
        _download(OXFORD_PET_ANNOTATIONS_URL, annotations_archive)

    images_dir = dataset_dir / "images"
    annotations_dir = dataset_dir / "annotations"

    if force_download or not images_dir.exists() or not any(images_dir.glob("*.jpg")):
        _safe_extract(images_archive, dataset_dir)
    if force_download or not annotations_dir.exists() or not any(
        annotations_dir.glob("*.txt")
    ):
        _safe_extract(annotations_archive, dataset_dir)

    return dataset_dir


def load_oxford_pet_labels(dataset_dir: Path) -> list[str]:
    list_path = dataset_dir / "annotations" / "list.txt"
    labels_by_idx: dict[int, str] = {}
    with list_path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            fields = line.split()
            if len(fields) < 2:
                continue
            breed_label = fields[0].strip().lower()
            class_idx = int(fields[1]) - 1
            labels_by_idx[class_idx] = breed_label

    if not labels_by_idx:
        raise ValueError(f"No class labels found in {list_path}")

    expected_count = max(labels_by_idx) + 1
    labels = ["" for _ in range(expected_count)]
    for class_idx, breed_label in labels_by_idx.items():
        labels[class_idx] = breed_label

    if any(not label for label in labels):
        raise ValueError("Class labels are incomplete in Oxford-IIIT Pet list.txt")

    return labels


def load_split_entries(dataset_dir: Path, split_name: str) -> list[tuple[str, int]]:
    split_path = dataset_dir / "annotations" / f"{split_name}.txt"
    entries: list[tuple[str, int]] = []
    with split_path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line:
                continue
            fields = line.split()
            if len(fields) < 2:
                continue
            image_id = fields[0]
            class_idx = int(fields[1]) - 1
            entries.append((image_id, class_idx))

    if not entries:
        raise ValueError(f"No entries found in split file: {split_path}")
    return entries


def _infer_breed_from_filename(filename: str) -> str:
    stem = Path(filename).stem
    match = re.match(r"^(?P<breed>.+)_(?P<index>\d+)$", stem)
    breed = match.group("breed") if match else stem
    return breed.strip().lower().replace("-", "_").replace(" ", "_")


def _find_image_root(dataset_dir: Path) -> Path:
    images_dir = dataset_dir / "images"
    if images_dir.exists() and any(images_dir.glob("*.jpg")):
        return images_dir
    if any(dataset_dir.glob("*.jpg")):
        return dataset_dir
    raise ValueError(
        f"No .jpg files found under {dataset_dir} or {images_dir}. "
        "Provide an Oxford-IIIT style images directory."
    )


def load_local_entries(dataset_dir: Path) -> tuple[list[str], list[tuple[Path, int]]]:
    image_root = _find_image_root(dataset_dir)
    image_paths = sorted(image_root.glob("*.jpg"))
    if not image_paths:
        raise ValueError(f"No .jpg files found in {image_root}")

    breeds = sorted({_infer_breed_from_filename(path.name) for path in image_paths})
    class_index = {breed: idx for idx, breed in enumerate(breeds)}

    entries: list[tuple[Path, int]] = []
    for image_path in image_paths:
        breed = _infer_breed_from_filename(image_path.name)
        entries.append((image_path, class_index[breed]))

    return breeds, entries


class OxfordPetBreedDataset(Dataset[tuple[torch.Tensor, int]]):
    def __init__(
        self,
        *,
        entries: list[tuple[Path, int]],
        image_size: int,
        train: bool,
    ) -> None:
        self._entries = entries
        self._image_size = image_size
        self._train = train

    def __len__(self) -> int:
        return len(self._entries)

    def __getitem__(self, index: int) -> tuple[torch.Tensor, int]:
        image_path, class_idx = self._entries[index]
        with Image.open(image_path) as image:
            tensor = preprocess_image(
                image,
                image_size=self._image_size,
                train=self._train,
            )
        return tensor, int(class_idx)


@dataclass(frozen=True)
class TrainingConfig:
    dataset_dir: Path
    checkpoint_path: Path
    image_size: int = 224
    batch_size: int = 32
    epochs: int = 5
    learning_rate: float = 3e-4
    weight_decay: float = 1e-4
    val_fraction: float = 0.1
    num_workers: int = 0
    seed: int = 42
    device: str = "cpu"
    force_download: bool = False


def _split_train_val(
    entries: list[tuple[Path, int]],
    *,
    val_fraction: float,
    seed: int,
) -> tuple[list[tuple[Path, int]], list[tuple[Path, int]]]:
    if not 0.0 < val_fraction < 0.5:
        raise ValueError("val_fraction must be between 0 and 0.5")

    shuffled = entries[:]
    rng = random.Random(seed)
    rng.shuffle(shuffled)

    val_size = max(1, int(round(len(shuffled) * val_fraction)))
    val_entries = shuffled[:val_size]
    train_entries = shuffled[val_size:]
    if not train_entries:
        raise ValueError("Train split is empty after applying val_fraction")

    return train_entries, val_entries


def _resolve_device(device: str) -> torch.device:
    if device == "auto":
        return torch.device("cuda" if torch.cuda.is_available() else "cpu")
    resolved = torch.device(device)
    if resolved.type == "cuda" and not torch.cuda.is_available():
        return torch.device("cpu")
    return resolved


def _set_global_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def _accuracy(logits: torch.Tensor, labels: torch.Tensor) -> float:
    preds = torch.argmax(logits, dim=1)
    correct = int((preds == labels).sum().item())
    total = int(labels.numel())
    return float(correct / max(1, total))


def _run_epoch(
    *,
    model: BreedNet,
    dataloader: DataLoader[tuple[torch.Tensor, torch.Tensor]],
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer | None,
    device: torch.device,
) -> tuple[float, float]:
    training = optimizer is not None
    model.train(training)

    total_loss = 0.0
    total_acc = 0.0
    batches = 0

    for images, labels in dataloader:
        images = images.to(device)
        labels = labels.to(device)

        if training:
            optimizer.zero_grad(set_to_none=True)

        logits = model(images)
        loss = criterion(logits, labels)

        if training:
            loss.backward()
            optimizer.step()

        total_loss += float(loss.item())
        total_acc += _accuracy(logits.detach(), labels)
        batches += 1

    if batches == 0:
        return 0.0, 0.0
    return total_loss / batches, total_acc / batches


def train_oxford_pet_breed_model(config: TrainingConfig) -> dict[str, float]:
    _set_global_seed(config.seed)
    dataset_dir = config.dataset_dir

    annotations_list = dataset_dir / "annotations" / "list.txt"
    trainval_list = dataset_dir / "annotations" / "trainval.txt"
    if annotations_list.exists() and trainval_list.exists():
        labels = load_oxford_pet_labels(dataset_dir)
        split_entries = load_split_entries(dataset_dir, "trainval")
        trainval_entries = [
            (dataset_dir / "images" / f"{image_id}.jpg", class_idx)
            for image_id, class_idx in split_entries
        ]
    else:
        if config.force_download:
            dataset_dir = download_oxford_iiit_pet(
                dataset_dir=config.dataset_dir,
                force_download=True,
            )
            labels = load_oxford_pet_labels(dataset_dir)
            split_entries = load_split_entries(dataset_dir, "trainval")
            trainval_entries = [
                (dataset_dir / "images" / f"{image_id}.jpg", class_idx)
                for image_id, class_idx in split_entries
            ]
        else:
            labels, trainval_entries = load_local_entries(dataset_dir)

    train_entries, val_entries = _split_train_val(
        trainval_entries,
        val_fraction=config.val_fraction,
        seed=config.seed,
    )

    train_dataset = OxfordPetBreedDataset(
        entries=train_entries,
        image_size=config.image_size,
        train=True,
    )
    val_dataset = OxfordPetBreedDataset(
        entries=val_entries,
        image_size=config.image_size,
        train=False,
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=config.batch_size,
        shuffle=True,
        num_workers=config.num_workers,
        collate_fn=collate_tensor_batch,
    )
    val_loader = DataLoader(
        val_dataset,
        batch_size=config.batch_size,
        shuffle=False,
        num_workers=config.num_workers,
        collate_fn=collate_tensor_batch,
    )

    device = _resolve_device(config.device)
    model = BreedNet(num_classes=len(labels)).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=config.learning_rate,
        weight_decay=config.weight_decay,
    )

    best_val_acc = -1.0
    best_state: dict[str, torch.Tensor] | None = None
    best_train_acc = 0.0

    for _epoch in range(config.epochs):
        _train_loss, train_acc = _run_epoch(
            model=model,
            dataloader=train_loader,
            criterion=criterion,
            optimizer=optimizer,
            device=device,
        )
        _val_loss, val_acc = _run_epoch(
            model=model,
            dataloader=val_loader,
            criterion=criterion,
            optimizer=None,
            device=device,
        )

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            best_train_acc = train_acc
            best_state = {
                key: value.detach().cpu().clone()
                for key, value in model.state_dict().items()
            }

    if best_state is not None:
        model.load_state_dict(best_state)

    metadata = {
        "dataset": "oxford_iiit_pet",
        "trained_at_utc": datetime.now(timezone.utc).isoformat(),
        "epochs": int(config.epochs),
        "batch_size": int(config.batch_size),
        "learning_rate": float(config.learning_rate),
        "weight_decay": float(config.weight_decay),
        "best_train_acc": float(best_train_acc),
        "best_val_acc": float(best_val_acc),
        "device": str(device),
    }
    save_model_checkpoint(
        checkpoint_path=config.checkpoint_path,
        model=model,
        labels=labels,
        image_size=config.image_size,
        cat_breeds=set(DEFAULT_CAT_BREEDS),
        metadata=metadata,
    )

    return {
        "best_train_acc": float(best_train_acc),
        "best_val_acc": float(best_val_acc),
        "num_train_samples": float(len(train_entries)),
        "num_val_samples": float(len(val_entries)),
    }


def predict_with_checkpoint(
    *,
    checkpoint_path: Path,
    image_path: Path,
    device: str = "cpu",
) -> dict[str, object]:
    classifier = OxfordPetBreedClassifier(checkpoint_path=checkpoint_path, device=device)
    image_bytes = image_path.read_bytes()
    prediction = classifier.predict(image_bytes)
    return {
        "species": prediction.species,
        "breed_top3": prediction.breed_top3,
    }


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Oxford-IIIT Pet breed classifier pipeline (download/train/predict)."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    download_cmd = subparsers.add_parser("download", help="Download Oxford-IIIT Pet dataset")
    download_cmd.add_argument("--data-dir", type=Path, default=default_dataset_dir())
    download_cmd.add_argument("--force", action="store_true")

    train_cmd = subparsers.add_parser("train", help="Train Oxford-IIIT Pet breed model")
    train_cmd.add_argument("--data-dir", type=Path, default=default_dataset_dir())
    train_cmd.add_argument("--checkpoint", type=Path, default=resolve_checkpoint_path())
    train_cmd.add_argument("--image-size", type=int, default=224)
    train_cmd.add_argument("--batch-size", type=int, default=32)
    train_cmd.add_argument("--epochs", type=int, default=5)
    train_cmd.add_argument("--lr", type=float, default=3e-4)
    train_cmd.add_argument("--weight-decay", type=float, default=1e-4)
    train_cmd.add_argument("--val-fraction", type=float, default=0.1)
    train_cmd.add_argument("--num-workers", type=int, default=0)
    train_cmd.add_argument("--seed", type=int, default=42)
    train_cmd.add_argument("--device", type=str, default="auto")
    train_cmd.add_argument("--force-download", action="store_true")

    predict_cmd = subparsers.add_parser("predict", help="Predict breed for one image")
    predict_cmd.add_argument("image", type=Path)
    predict_cmd.add_argument("--checkpoint", type=Path, default=resolve_checkpoint_path())
    predict_cmd.add_argument("--device", type=str, default="cpu")

    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()

    if args.command == "download":
        try:
            dataset_dir = download_oxford_iiit_pet(
                dataset_dir=args.data_dir,
                force_download=args.force,
            )
        except RuntimeError as exc:
            print(str(exc))
            return 1
        print(f"Downloaded Oxford-IIIT Pet dataset to: {dataset_dir}")
        return 0

    if args.command == "train":
        try:
            metrics = train_oxford_pet_breed_model(
                TrainingConfig(
                    dataset_dir=args.data_dir,
                    checkpoint_path=args.checkpoint,
                    image_size=args.image_size,
                    batch_size=args.batch_size,
                    epochs=args.epochs,
                    learning_rate=args.lr,
                    weight_decay=args.weight_decay,
                    val_fraction=args.val_fraction,
                    num_workers=args.num_workers,
                    seed=args.seed,
                    device=args.device,
                    force_download=args.force_download,
                )
            )
        except RuntimeError as exc:
            print(str(exc))
            return 1
        print("Training complete.")
        for key, value in metrics.items():
            print(f"{key}: {value:.4f}")
        print(f"checkpoint: {args.checkpoint}")
        return 0

    if args.command == "predict":
        result = predict_with_checkpoint(
            checkpoint_path=args.checkpoint,
            image_path=args.image,
            device=args.device,
        )
        print(result)
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
