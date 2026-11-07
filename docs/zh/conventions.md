# 约定

这些规则会写进生成项目的 `docs/best-practices.md`。那份文件保持英文。本页用中文说明同一套规则，给阅读模板的人看。

## 语言

标识符、注释、文档字符串、CLI 帮助、提交说明，以及其他给开发者看的文字，使用清楚的英文。用别的语言提出的需求，写出来的代码仍然是英文。把需求的意思保留下来。

## 布局

| 路径 | 作用 |
| --- | --- |
| `src/my_exp` | 可导入的包（Hatch 的 `src` 布局）。 |
| `configs/` | Hydra（`configs/hydra`）和 Accelerate 的配置。 |
| `tests/` | pytest，与包的布局对应。 |
| `artifacts/` | 运行产物：Hydra 运行目录、检查点、日志。 |
| `docs/` | 这个项目自己的设计笔记和数学说明。 |
| `legacy/` | 以后可以加的历史代码目录。Ruff 和 ty 排除。 |
| `pkgs/` | 可选的第三方或工作区包。`--mlkit` 把钉住的 `my_pkg_py` 克隆到这里。除非明确要改它，否则把它当参考。 |
| `data/` | 以后可以加的数据集和其他输入。被 gitignore。 |

用 `.project-root` 标记和 `paths.py` 定位仓库。不要依赖进程的当前目录。

## 环境

除非 `--python` 另有指定，使用 Python 3.12。用 uv，不用裸的 `python` 或 `pip`。

一次性命令走 `uv run`。交互式会话可以 `source .venv/bin/activate`。包是私有的（`Private :: Do Not Upload`）。

## 质量门

Python 的改动做完之前：

```bash
uv run ruff check
uv run ty check
```

失败就修，然后两个都再跑一遍。自动修复用 `uv run ruff check --fix`，然后 `uv run ruff format`。

优先使用 `from __future__ import annotations`、`X | None`，配置对象用冻结的 dataclass。Ruff 和 ty 的具体配置见[质量检查](quality.md)。

## Shell 脚本

从项目根目录调用 `bash shell_script/...`。脚本使用 `set -euo pipefail`。帮助是英文：`@help-begin` 写摘要，`@help-options-begin` 写每一个参数，包括 `-h` / `--help`。

GPU 走 `shell_script/mc-run-python.sh`。CPU 走 `shell_script/run-python.sh`。拉文件用 `shell_script/file_sync/r2l.sh`，不加 `--run` 时只做 dry-run。Slurm 批处理脚本从仓库根目录提交，并 source `shell_script/hpc/env.sh`。依赖在登录节点上同步。

不要提交 SMTP 密钥。把它们放在被 gitignore 的 `shell_script/env_email.sh`。

## Hydra 和训练

配置组合放在 `configs/hydra`。入口使用 `@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")`。

Hydra 的 run 和 sweep 目录、检查点、日志都在 `artifacts/` 下。带了 `--mlkit` 时，训练走 `mlkit.pipeline`，`pkgs/my_pkg_py` 是被 gitignore 的可编辑检出，提交钉在模板子模块上。

不要提交 `artifacts/`、数据集、`.env` 或含有密钥的脚本。
