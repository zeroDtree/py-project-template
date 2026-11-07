# Python project template

Scaffold a new Python / ML-research repo with uv, Ruff, ty, pytest, Hydra, and an `artifacts/` layout.

This repository only initializes new projects. `init.sh` refuses a destination that already has files. It does not update an existing repo.

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

The default project has no training loop and no AI editor rules. Add [`--mlkit`](mlkit.md) for the pinned training pipeline, and [`--lorebook`](lorebook.md) for Cursor, Copilot, and Claude rules.

This site documents the template. A project created from it keeps its own English notes in `docs/best-practices.md`. The site is not copied into that project.

Continue with [Getting started](getting-started.md).
