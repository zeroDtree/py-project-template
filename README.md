# Python project template

Scaffold a new Python / ML-research repo with uv, Ruff, ty, Hydra, and an `artifacts/` layout.

This template **only initializes new projects**. It will refuse a non-empty destination.

## Init

```bash
bash /Users/zengls/repo/py-project-template/init.sh \
  --dest /Users/zengls/repo/my-exp \
  --name my-exp
```

Optional flags:

```bash
bash /Users/zengls/repo/py-project-template/init.sh --help
```

`--name` defaults to the destination basename. `--package` defaults to that name with `-` replaced by `_`. `--python` defaults to `3.12`. Pass `--no-git` to skip `git init`.

## After init

`init.sh` copies `overlay/` then applies Cursor / Copilot / Claude rules from `ai-lorebook/apply.sh`. To refresh those rules later:

```bash
bash /Users/zengls/repo/py-project-template/ai-lorebook/apply.sh \
  -d /Users/zengls/repo/my-exp -f
```

```bash
cd /Users/zengls/repo/my-exp
uv sync
uv run ruff check
uv run ty check
uv run pytest
uv run python -m my_exp.cli --help
```

Importable code lives in `src/<package>`. Configuration is under `configs`. Runtime outputs go under `artifacts`. Conventions are in `docs/best-practices.md`.
