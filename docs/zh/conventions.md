# 约定

生成项目里的 `docs/best-practices.md` 是这套规则的英文版。

## 语言

标识符、注释、docstring、CLI 帮助和提交说明用英文。

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

仓库根是放着 `.project-root` 的那一层。`paths.py` 从那里读路径。

## 环境

默认 Python 3.12，`--python` 另有指定时除外。用 uv。

单次命令用 `uv run`。交互式会话可以 `source .venv/bin/activate`。包是私有的（`Private :: Do Not Upload`）。

## 检查

Python 改动收尾时：

```bash
uv run ruff check
uv run ty check
```

没过就改，两个都再跑。自动改用 `uv run ruff check --fix`，接着 `uv run ruff format`。

生成代码用 `from __future__ import annotations` 和 `X | None`，配置对象用冻结 dataclass。Ruff 和 ty 的具体项在[质量检查](quality.md)。

## Shell 脚本

在项目根目录跑 `bash shell_script/...`。脚本有 `set -euo pipefail`。帮助是英文：`@help-begin` 写摘要，`@help-options-begin` 写每一个参数，包括 `-h` / `--help`。

GPU 用 `shell_script/mc-run-python.sh`，CPU 用 `shell_script/run-python.sh`。拉文件用 `shell_script/file_sync/r2l.sh`，加上 `--run` 才真正复制。Slurm 批处理从仓库根提交，并 source `shell_script/hpc/env.sh`。依赖在登录节点上同步。

SMTP 密码放在 gitignore 的 `shell_script/env_email.sh`，不要提交。

## Hydra 和训练

配置写在 `configs/hydra`。入口是 `@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")`。

Hydra 的 run、sweep、检查点和日志都在 `artifacts/` 下。`--mlkit` 的训练走 `mlkit.pipeline`。`pkgs/my_pkg_py` 是 gitignore 的可编辑检出，提交钉在模板子模块上。

`artifacts/`、数据集、`.env` 和带密钥的脚本留在 git 外面。
