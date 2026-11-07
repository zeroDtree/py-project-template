# 质量检查

生成的项目里，Python 的检查是 Ruff 和 ty。两者都只覆盖包和测试。

```bash
uv run ruff check
uv run ty check
uv run pytest
```

先修 Ruff，再格式化：

```bash
uv run ruff check --fix
uv run ruff format
```

修完再把 `ruff check` 和 `ty check` 都跑一遍。前一个通过，不代表后一个也通过。

## 范围

`ruff.toml` 包含 `src/my_exp/**/*.py` 和 `tests/**/*.py`。`ty.toml` 包含同样的两棵树。

`legacy/`、`pkgs/`、`artifacts/` 一旦存在，两份配置都会排除它们。Ruff 还会跳过常见的虚拟环境、构建目录和版本库目录。以下划线开头的名字可以不使用。

Ruff 与 Black 兼容：行宽 120、空格缩进、双引号。启用的规则是 pycodestyle 的 `E4`、`E7`、`E9`，Pyflakes 的 `F`，以及 isort 的 `I`。`E741`（有歧义的变量名）被忽略。Ruff 的 target 跟 Python 版本走，3.12 对应 `py312`。

ty 把 `import-not-found` 设为 ignore。

## pytest

```toml
[tool.pytest.ini_options]
pythonpath = ["src", "."]
testpaths = ["tests"]
```

示例测试检查 `.project-root` 是否存在、`configs/hydra/default.yaml` 是否存在，以及 `project_path` 是否从仓库根解析相对配置路径。

## 脚手架里的写法

生成的 Python 使用 `from __future__ import annotations` 和 `X | None`。新增配置对象时优先用冻结的 dataclass。标识符、注释、文档字符串和 CLI 帮助保持英文。见[约定](conventions.md)。
