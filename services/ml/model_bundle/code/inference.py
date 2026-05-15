"""SageMaker serving entry point — EfficientNet-B3 galaxy morphology classifier.

Model bundle layout expected in /opt/ml/model/:
  best.pth   — checkpoint produced by training (state_dict wrapped in dict or raw)
  code/
    inference.py        ← this file
    requirements.txt

Input  : raw image bytes (JPEG/PNG), content-type application/octet-stream
Output : JSON  {"label": str, "confidence": float, "probabilities": {class: float}}
"""

from __future__ import annotations

import io
import json
import os

import torch
import torch.nn as nn
from PIL import Image
from torchvision import models, transforms

CLASSES: list[str] = [
    "Elliptical",
    "Lenticular",
    "Spiral",
    "Barred_Spiral",
    "Edge_on",
    "Irregular",
]

CROP_SIZE: int = 320
IMAGE_SIZE: int = 224

_IMAGENET_MEAN = [0.485, 0.456, 0.406]
_IMAGENET_STD  = [0.229, 0.224, 0.225]

_preprocess = transforms.Compose([
    transforms.CenterCrop(CROP_SIZE),
    transforms.Resize(IMAGE_SIZE),
    transforms.ToTensor(),
    transforms.Normalize(mean=_IMAGENET_MEAN, std=_IMAGENET_STD),
])


def model_fn(model_dir: str) -> nn.Module:
    """Load EfficientNet-B3 with custom 6-class head from best.pth checkpoint."""
    base = models.efficientnet_b3(weights=None)
    in_features = base.classifier[1].in_features  # 1536
    base.classifier[1] = nn.Linear(in_features, len(CLASSES))

    model_path = os.path.join(model_dir, "best.pth")
    checkpoint = torch.load(model_path, map_location="cpu", weights_only=False)

    state_dict = checkpoint.get("model_state_dict", checkpoint)

    if any(k.startswith("_orig_mod.") for k in state_dict):
        state_dict = {k.removeprefix("_orig_mod."): v for k, v in state_dict.items()}

    base.load_state_dict(state_dict)
    base.eval()
    return base


def input_fn(request_body: bytes, content_type: str) -> torch.Tensor:
    """Decode raw image bytes and apply the inference preprocessing pipeline."""
    supported = ("application/octet-stream", "image/jpeg", "image/png")
    if content_type not in supported:
        raise ValueError(
            f"Unsupported content-type: {content_type!r}. Supported: {supported}"
        )

    image = Image.open(io.BytesIO(request_body)).convert("RGB")
    return _preprocess(image).unsqueeze(0)


def predict_fn(input_data: torch.Tensor, model: nn.Module) -> dict:
    """Run forward pass and convert logits to label + probabilities."""
    with torch.no_grad():
        logits = model(input_data)
    probs = torch.softmax(logits, dim=1)
    confidence, pred_idx = probs.max(dim=1)

    return {
        "label": CLASSES[pred_idx.item()],
        "confidence": round(confidence.item(), 4),
        "probabilities": {
            cls: round(p, 4)
            for cls, p in zip(CLASSES, probs[0].tolist())
        },
    }


def output_fn(prediction: dict, accept: str) -> tuple[str, str]:
    """Serialize prediction to JSON."""
    return json.dumps(prediction), "application/json"
