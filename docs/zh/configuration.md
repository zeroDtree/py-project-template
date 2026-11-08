# 配置与产物

配置用 Hydra，源文件在 `configs/hydra`。输出在 `artifacts/`。这两处都由 `paths.py` 从仓库根定位。见 [Python 环境](environment.md)。

## 基础配置

`configs/hydra/default.yaml` 选了三组：

```yaml
defaults:
  - train/default
  - log/default
  - hydra/default@_here_
  - _self_
```

| 文件 | 内容 |
| --- | --- |
| `configs/hydra/train/default.yaml` | `seed: 31`、一个 epoch、`batch_size: 1`、`device: cuda`、检查点在 `artifacts/checkpoints`、eval 和 save 的步数，以及 `mixed_precision: "no"`。 |
| `configs/hydra/log/default.yaml` | `log_dir: artifacts/logs`，以及日志步数、epoch 和策略。 |
| `configs/hydra/hydra/default.yaml` | Hydra 自己的输出目录，见下一节。 |

`--mlkit` 再往这份 defaults 里加 `optimizer`、`model`、`dataset`、`wandb`。基础 CLI 读上面这三组。

## 输出目录

```yaml
hydra:
  run:
    dir: artifacts/hydra/${now:%Y-%m-%d}/${now:%H-%M-%S}
  sweep:
    dir: artifacts/hydra-multirun/${now:%Y-%m-%d}/${now:%H-%M-%S}
    subdir: ${hydra.job.num}
```

检查点目录来自训练配置里的 `artifacts/checkpoints`。日志在 `artifacts/logs`。GPU 启动脚本还会往 `artifacts/command_logs/` 追加一行。`artifacts/` 整目录都在 gitignore 里。

## CLI

基础的 `src/my_exp/cli.py` 读配置，然后打印：

```python
@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")
def main(cfg: DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))
```

`config_path` 用 `paths.py` 给出的绝对目录。

```bash
uv run python -m my_exp.cli --help
uv run python -m my_exp.cli train.seed=0
```

加了 `--mlkit` 之后，这个入口调用 `train.run(cfg)`。见 [mlkit](mlkit.md)。

## Accelerate

`configs/accelerate/acc_cfg_base.yaml` 给 `shell_script/mc-run-python.sh` 用。本机多 GPU：`distributed_type: MULTI_GPU`，`use_cpu: false`，`mixed_precision: "no"`。脚本把可见 GPU 数量传给 `--num_processes`，并选一个主进程端口。CPU 走 `run-python.sh`。
