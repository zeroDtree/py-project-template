# Python project template

Scaffold a new Python / ML-research repo with uv, Ruff, ty, pytest, Hydra, and an `artifacts/` layout.

`init.sh` writes into an empty directory and exits if that directory already has files.

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

Pass [`--mlkit`](mlkit.md) for the pinned training pipeline, and [`--lorebook`](lorebook.md) for Cursor, Copilot, and Claude rules.

This site covers the template. A generated project keeps its own English notes in `docs/best-practices.md`. Usage is on [Getting started](getting-started.md).
