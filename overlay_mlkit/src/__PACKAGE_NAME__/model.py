from __future__ import annotations

from typing import Any

from omegaconf import DictConfig
from torch import Tensor, nn


class ToyModel(nn.Module):
    """Minimal linear model whose forward returns a dict with ``loss``."""

    def __init__(self, dim: int = 8) -> None:
        super().__init__()
        self.net = nn.Linear(dim, dim)

    def forward(self, **batch: Any) -> dict[str, Tensor]:
        pred = self.net(batch["x"])
        loss = ((pred - batch["y"]) ** 2).mean()
        return {"loss": loss}


def get_model(cfg: DictConfig) -> dict[str, ToyModel]:
    return {"model": ToyModel(dim=int(cfg.model.dim))}
