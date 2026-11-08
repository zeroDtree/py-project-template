# Python 项目模板

用 uv、Ruff、ty、pytest、Hydra 和 `artifacts/` 搭一个新的 Python / ML 研究仓库。

`init.sh` 往空目录里写。目录里已经有文件就退出。

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

训练流水线加 [`--mlkit`](mlkit.md)，Cursor、Copilot、Claude 的规则加 [`--lorebook`](lorebook.md)。

这个站讲模板怎么用。生成出来的项目自己有一份英文说明，在 `docs/best-practices.md`。用法见[快速开始](getting-started.md)。
