from __future__ import annotations

from mlkit.util.experiment import TrainSpec, run_experiment
from omegaconf import DictConfig

from __PACKAGE_NAME__.data import get_collate_fn, get_dataset
from __PACKAGE_NAME__.model import get_model

SPEC = TrainSpec(
    get_model=get_model,
    get_dataset=get_dataset,
    get_collate=get_collate_fn,
)


def run(cfg: DictConfig) -> None:
    """Train through the mlkit experiment runner."""
    run_experiment(cfg, SPEC)
