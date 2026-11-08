# 质量检查

Ruff 和 ty 检查包和测试。

```bash
uv run ruff check
uv run ty check
uv run pytest
```

先改 Ruff 报的问题，再格式化：

```bash
uv run ruff check --fix
uv run ruff format
```

改完把 `ruff check` 和 `ty check` 再跑一遍。

## 范围

`ruff.toml` 收录 `src/my_exp/**/*.py` 和 `tests/**/*.py`。`ty.toml` 同样这两处。

`legacy/`、`pkgs/`、`artifacts/` 出现之后，两份配置都会排除。Ruff 另外跳过常见的虚拟环境、构建目录和版本库目录。下划线开头的名字可以闲置。

Ruff 按 Black 的习惯：行宽 120，空格缩进，双引号。规则是 pycodestyle 的 `E4`、`E7`、`E9`，Pyflakes 的 `F`，以及 isort 的 `I`。`E741`（容易看混的变量名）忽略。Ruff target 跟着 Python 版本，3.12 就是 `py312`。

ty 把 `import-not-found` 设成 ignore。

## pytest

```toml
[tool.pytest.ini_options]
pythonpath = ["src", "."]
testpaths = ["tests"]
```

自带的测试看三件事：`.project-root` 在不在，`configs/hydra/default.yaml` 在不在，`project_path` 能不能从仓库根解析一条相对配置路径。

## 代码风格

生成的 Python 带 `from __future__ import annotations`，联合类型写成 `X | None`。新的配置对象用冻结 dataclass。标识符、注释、docstring 和 CLI 帮助用英文。见[约定](conventions.md)。
