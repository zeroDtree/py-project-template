from __future__ import annotations

from typing import Any, cast

import wandb
from accelerate import Accelerator
from omegaconf import DictConfig, OmegaConf

from mlkit.pipeline.pipeline import LogConfig
from mlkit.util.log import get_and_create_new_log_dir, get_logger
from mlkit.util.seed import seed_everything
from mlkit.util.show import show_info
from mlkit.util.utils_for_main import (
    get_learing_rate_scheduler,
    get_new_save_dir,
    get_optimizer,
    get_run_name,
    get_train_class,
)

from __PACKAGE_NAME__.data import get_collate_fn, get_dataset
from __PACKAGE_NAME__.model import get_model


def run(cfg: DictConfig) -> None:
    """Train with the mlkit distributed pipeline."""
    seed_everything(cfg.train.seed)

    accelerator = Accelerator(mixed_precision=cfg.train.mixed_precision)
    print(f"accelerator.device = {accelerator.device}")

    logger = None
    if accelerator.is_local_main_process:
        log_dir = get_and_create_new_log_dir(cfg.log.log_dir)
        logger = get_logger(name="experiment", log_dir=log_dir)
        logger.info(f"accelerator.device = {accelerator.device}")
        logger.info(f"seed = {cfg.train.seed}")
        run_name = get_run_name(cfg)
        logger.info("Config:\n" + OmegaConf.to_yaml(cfg))
        wandb.init(
            reinit=cfg.wandb.reinit,
            mode=cfg.wandb.mode,
            project=cfg.wandb.project,
            name=run_name,
            group=cfg.wandb.group,
            entity=cfg.wandb.get("entity") or None,
            config=cast(dict[str, Any], OmegaConf.to_container(cfg, resolve=True)),
        )

    model_result = get_model(cfg)
    if not isinstance(model_result, dict):
        model_result = {"model": model_result}
    model = model_result["model"]

    train_set, val_set, _ = get_dataset(cfg)
    optimizer = get_optimizer(model, cfg)
    lr_scheduler = get_learing_rate_scheduler(optimizer, accelerator, train_set, cfg)
    show_info(model=model, optimizer=optimizer)

    log_config = LogConfig(**cfg.log)
    pipeline_cls, training_config_cls = get_train_class()
    training_config = training_config_cls(**cfg.train)
    if accelerator.is_local_main_process:
        training_config.save_dir = get_new_save_dir(training_config.save_dir, cfg)

    pipeline = pipeline_cls(
        model=model,
        train_dataset=train_set,
        eval_dataset=val_set,
        optimizers=(optimizer, lr_scheduler),
        training_config=training_config,
        log_config=log_config,
        collate_fn=get_collate_fn(cfg),
        logger=logger,
    )
    pipeline.train()

    if accelerator.is_local_main_process:
        wandb.finish()
