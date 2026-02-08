from __future__ import annotations

import io
import random
from typing import Any

import numpy as np
import torch
from PIL import Image

IMAGENET_MEAN = torch.tensor([0.485, 0.456, 0.406], dtype=torch.float32).view(3, 1, 1)
IMAGENET_STD = torch.tensor([0.229, 0.224, 0.225], dtype=torch.float32).view(3, 1, 1)


ImageInput = Image.Image | bytes | bytearray | memoryview | np.ndarray


def _to_pil_rgb(image: ImageInput) -> Image.Image:
    if isinstance(image, Image.Image):
        return image.convert("RGB")

    if isinstance(image, (bytes, bytearray, memoryview)):
        with Image.open(io.BytesIO(bytes(image))) as pil:
            return pil.convert("RGB")

    if isinstance(image, np.ndarray):
        if image.ndim != 3 or image.shape[2] != 3:
            raise ValueError("NumPy image input must have shape [H, W, 3].")
        if image.dtype != np.uint8:
            image = image.astype(np.uint8)
        return Image.fromarray(image, mode="RGB")

    raise TypeError(f"Unsupported image input type: {type(image)!r}")


def _random_square_crop(image: Image.Image, min_scale: float = 0.72) -> Image.Image:
    width, height = image.size
    side = min(width, height)
    crop_side = int(round(side * random.uniform(min_scale, 1.0)))
    crop_side = max(8, min(side, crop_side))

    max_left = max(0, width - crop_side)
    max_top = max(0, height - crop_side)
    left = random.randint(0, max_left) if max_left else 0
    top = random.randint(0, max_top) if max_top else 0
    return image.crop((left, top, left + crop_side, top + crop_side))


def _center_square_crop(image: Image.Image) -> Image.Image:
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side))


def _image_to_tensor(image: Image.Image) -> torch.Tensor:
    array = np.asarray(image, dtype=np.float32) / 255.0
    tensor = torch.from_numpy(array).permute(2, 0, 1).contiguous()
    return (tensor - IMAGENET_MEAN) / IMAGENET_STD


def preprocess_image(image: ImageInput, *, image_size: int, train: bool) -> torch.Tensor:
    """Convert image input into a normalized CHW float tensor."""
    pil = _to_pil_rgb(image)

    if train:
        pil = _random_square_crop(pil)
        if random.random() < 0.5:
            pil = pil.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    else:
        pil = _center_square_crop(pil)

    pil = pil.resize((image_size, image_size), Image.Resampling.BILINEAR)
    return _image_to_tensor(pil)


def preprocess_batch(images: list[ImageInput], *, image_size: int, train: bool) -> torch.Tensor:
    tensors = [preprocess_image(image, image_size=image_size, train=train) for image in images]
    return torch.stack(tensors, dim=0)


def collate_tensor_batch(samples: list[tuple[torch.Tensor, int]]) -> tuple[torch.Tensor, torch.Tensor]:
    if not samples:
        raise ValueError("Cannot collate an empty batch.")
    images = torch.stack([item[0] for item in samples], dim=0)
    labels = torch.tensor([int(item[1]) for item in samples], dtype=torch.long)
    return images, labels
