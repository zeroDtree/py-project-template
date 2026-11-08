# Configuration and artifacts

Hydra composes configuration from `configs/hydra`. Outputs go under `artifacts/`. `paths.py` finds those directories from the repository. See [Environment](environment.md).

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

`--mlkit` adds `optimizer`, `model`, `dataset`, and `wandb` to that defaults list. The base CLI reads the three groups above.

## Output paths

```yaml
hydra:
  run:
    dir: artifacts/hydra/${now:%Y-%m-%d}/${now:%H-%M-%S}
  sweep:
    dir: artifacts/hydra-multirun/${now:%Y-%m-%d}/${now:%H-%M-%S}
    subdir: ${hydra.job.num}
```

Checkpoints use `artifacts/checkpoints` from the train config. Logs use `artifacts/logs`. The GPU runner also appends a line under `artifacts/command_logs/`. All of `artifacts/` is gitignored.

## CLI

The base `src/my_exp/cli.py` loads the config and prints it:

```python
@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")
def main(cfg: DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))
```

`config_path` is the absolute directory from `paths.py`.

```bash
uv run python -m my_exp.cli --help
uv run python -m my_exp.cli train.seed=0
```

With `--mlkit`, that entrypoint calls `train.run(cfg)`. See [mlkit](mlkit.md).

## Accelerate

`configs/accelerate/acc_cfg_base.yaml` is the launch config for `shell_script/mc-run-python.sh`. It is a local multi-GPU config: `distributed_type: MULTI_GPU`, `use_cpu: false`, and `mixed_precision: "no"`. The script passes the visible GPU count as `--num_processes` and picks a main-process port. CPU runs go through `run-python.sh`.
