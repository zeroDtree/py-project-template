# Configuration and artifacts

Configuration is composed with Hydra from `configs/hydra`. Outputs go under `artifacts/`. Code finds those directories through `paths.py`, so the process current directory does not matter. See [Environment](environment.md).

## Base configs

`configs/hydra/default.yaml` selects three groups:

```yaml
defaults:
  - train/default
  - log/default
  - hydra/default@_here_
  - _self_
```

| File | What it sets |
| --- | --- |
| `configs/hydra/train/default.yaml` | `seed: 31`, one epoch, `batch_size: 1`, `device: cuda`, checkpoints at `artifacts/checkpoints`, eval and save steps, `mixed_precision: "no"`. |
| `configs/hydra/log/default.yaml` | `log_dir: artifacts/logs`, plus the log step, epoch, and strategy fields. |
| `configs/hydra/hydra/default.yaml` | Hydra's own output directories, below. |

`--mlkit` adds `optimizer`, `model`, `dataset`, and `wandb` to that defaults list. The base CLI does not read those groups.

## Where runs are written

```yaml
hydra:
  run:
    dir: artifacts/hydra/${now:%Y-%m-%d}/${now:%H-%M-%S}
  sweep:
    dir: artifacts/hydra-multirun/${now:%Y-%m-%d}/${now:%H-%M-%S}
    subdir: ${hydra.job.num}
```

Checkpoints use `artifacts/checkpoints` from the train config. Logs use `artifacts/logs`. The GPU runner also appends a line under `artifacts/command_logs/`. All of `artifacts/` is gitignored.

## The CLI

The base `src/my_exp/cli.py` loads the config and prints it:

```python
@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")
def main(cfg: DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))
```

`config_path` is the absolute directory from `paths.py`, not a path relative to the shell's current directory.

```bash
uv run python -m my_exp.cli --help
uv run python -m my_exp.cli train.seed=0
```

With `--mlkit`, the same entrypoint calls `train.run(cfg)` instead of printing. That path is described on the [mlkit](mlkit.md) page.

## Accelerate

`configs/accelerate/acc_cfg_base.yaml` is the launch config for `shell_script/mc-run-python.sh`. It is a local multi-GPU config: `distributed_type: MULTI_GPU`, `use_cpu: false`, and `mixed_precision: "no"`. The script passes the visible GPU count as `--num_processes` and picks a main-process port. CPU runs do not use this file; they go through `run-python.sh`.
