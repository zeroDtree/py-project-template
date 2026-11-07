# Python 项目模板

用 uv、Ruff、ty、pytest、Hydra 和 `artifacts/` 目录，初始化一个新的 Python / ML 研究仓库。

这个仓库只负责创建新项目。目标目录里已经有文件时，`init.sh` 会拒绝执行。它不会去更新一个已有仓库。

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

默认项目没有训练循环，也没有 AI 编辑器规则。训练流水线用 [`--mlkit`](mlkit.md)，Cursor、Copilot 和 Claude 的规则用 [`--lorebook`](lorebook.md)。

本站说明的是这个模板。用它创建出来的项目，自己的约定写在英文文件 `docs/best-practices.md` 里。文档站不会被拷进那个项目。

接下来看[快速开始](getting-started.md)。
