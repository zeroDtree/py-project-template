from __future__ import annotations

from collections.abc import Callable
from typing import Any

import torch
from omegaconf import DictConfig
from torch.utils.data import Dataset, default_collate


class ToyDataset(Dataset):
    """Fixed random pairs used as a stand-in until a real dataset exists."""

    def __init__(self, n_samples: int, dim: int, seed: int) -> None:
        generator = torch.Generator().manual_seed(seed)
        self.x = torch.randn(n_samples, dim, generator=generator)
        self.y = torch.randn(n_samples, dim, generator=generator)

    def __len__(self) -> int:
        return int(self.x.shape[0])

    def __getitem__(self, index: int) -> dict[str, torch.Tensor]:
        return {"x": self.x[index], "y": self.y[index]}


def get_dataset(cfg: DictConfig) -> tuple[ToyDataset, ToyDataset, None]:
    dim = int(cfg.model.dim)
    n_samples = int(cfg.dataset.n_samples)
    seed = int(cfg.train.seed)
    train_set = ToyDataset(n_samples, dim, seed)
    eval_set = ToyDataset(max(n_samples // 4, 1), dim, seed + 1)
    return train_set, eval_set, None


def get_collate_fn(_cfg: DictConfig) -> Callable[[list[Any]], Any]:
    return default_collate
