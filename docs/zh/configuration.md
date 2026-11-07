# 配置与产物

配置用 Hydra，从 `configs/hydra` 组合。输出写到 `artifacts/` 下面。代码通过 `paths.py` 找到这些目录，所以进程的当前目录无关。见 [Python 环境](environment.md)。

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

`--mlkit` 会在这份 defaults 里再加上 `optimizer`、`model`、`dataset` 和 `wandb`。基础 CLI 不读这些组。

## 运行结果写到哪里

```yaml
hydra:
  run:
    dir: artifacts/hydra/${now:%Y-%m-%d}/${now:%H-%M-%S}
  sweep:
    dir: artifacts/hydra-multirun/${now:%Y-%m-%d}/${now:%H-%M-%S}
    subdir: ${hydra.job.num}
```

检查点用训练配置里的 `artifacts/checkpoints`。日志用 `artifacts/logs`。GPU 启动脚本还会往 `artifacts/command_logs/` 追加一行。整个 `artifacts/` 都被 gitignore。

## CLI

基础的 `src/my_exp/cli.py` 加载配置并打印：

```python
@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")
def main(cfg: DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))
```

`config_path` 是 `paths.py` 给出的绝对目录，不是相对于 shell 当前目录的路径。

```bash
uv run python -m my_exp.cli --help
uv run python -m my_exp.cli train.seed=0
```

带了 `--mlkit` 时，同一个入口改为调用 `train.run(cfg)`，不再打印配置。那条路径写在 [mlkit](mlkit.md)。

## Accelerate

`configs/accelerate/acc_cfg_base.yaml` 是 `shell_script/mc-run-python.sh` 的启动配置。它是本机多 GPU 配置：`distributed_type: MULTI_GPU`、`use_cpu: false`、`mixed_precision: "no"`。脚本把可见 GPU 的数量传给 `--num_processes`，并选一个主进程端口。CPU 运行不使用这个文件，走 `run-python.sh`。
