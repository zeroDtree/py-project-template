# Quality checks

Ruff and ty are the gates for Python in a generated project. Both are limited to the package and the tests.

```bash
uv run ruff check
uv run ty check
uv run pytest
```

Fix Ruff findings, then format:

```bash
uv run ruff check --fix
uv run ruff format
```

Run `ruff check` and `ty check` again after a fix. A green first command does not imply the second one is green.

## Scope

`ruff.toml` includes `src/my_exp/**/*.py` and `tests/**/*.py`. `ty.toml` includes the same two trees.

Both configs exclude `legacy/`, `pkgs/`, and `artifacts/` when those directories exist. Ruff also skips the usual virtualenv, build, and VCS directories. Underscore-prefixed names may be unused.

Ruff is Black-compatible: line length 120, spaces, double quotes. The enabled rules are the pycodestyle errors `E4`, `E7`, and `E9`, Pyflakes `F`, and isort `I`. `E741` (ambiguous variable names) is ignored. The Ruff target matches the Python version, `py312` for 3.12.

ty sets `import-not-found` to ignore.

## pytest

```toml
[tool.pytest.ini_options]
pythonpath = ["src", "."]
testpaths = ["tests"]
```

The sample test checks that `.project-root` exists, that `configs/hydra/default.yaml` exists, and that `project_path` resolves a relative config path from the repository root.

## Style used by the scaffold

Generated Python uses `from __future__ import annotations` and `X | None` unions. Prefer a frozen dataclass when you add a config object. Identifiers, comments, docstrings, and CLI help stay in English. See [Conventions](conventions.md).
