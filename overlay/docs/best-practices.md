# Best practices

Conventions this project follows. Keep generated code in English even when notes are in another language.

## Language and collaboration

- Identifiers, comments, docstrings, CLI help, commit messages, and developer-facing text use clear English.
- Preserve the intent of non-English requests; still emit English code.

## Layout

| Path | Role |
| --- | --- |
| `src/__PACKAGE_NAME__` | Importable package (Hatch `src` layout) |
| `configs/` | Hydra (`configs/hydra`) and Accelerate configuration |
| `tests/` | pytest, mirrored to the package layout |
| `artifacts/` | Runtime outputs: Hydra runs, checkpoints, logs |
| `docs/` | Design notes and math write-ups |
| `legacy/` | Optional later dir for historical code; excluded from Ruff and ty |
| `pkgs/` | Optional later dir for third-party or workspace packages; treat as reference unless asked to edit |
| `data/` | Optional later dir for datasets and other input files; gitignored, do not commit |

Locate the repo with the `.project-root` marker and `paths.py` (`PROJECT_ROOT`, `HYDRA_CONFIG_ROOT`, `ARTIFACT_ROOT`). Do not depend on the process CWD.

## Python environment

- Python `__PYTHON_VERSION__`. Use **uv**, not bare `python` / `pip`.
- One-off commands: `uv run python -m __PACKAGE_NAME__.cli`, `uv run pytest`.
- Interactive sessions may `source .venv/bin/activate`.
- The package is private (`Private :: Do Not Upload`).

## Quality gates

Ruff (Black-compatible, line length 120) and ty. Scope is `src/__PACKAGE_NAME__` and `tests`. Exclude `legacy/`, `pkgs/`, and `artifacts/` if those directories exist. Underscore-prefixed names may be unused.

Before finishing Python work:

```bash
uv run ruff check
uv run ty check
```

Fix failures and re-run both. Auto-fix with `uv run ruff check --fix` then `uv run ruff format`.

Prefer `from __future__ import annotations`, `X | None` types, and frozen dataclasses for config objects.

## Shell scripts

See [shell_script/README.md](../shell_script/README.md). Invoke as `bash shell_script/...` from the project root.

- Use `set -euo pipefail`.
- Split help into `@help-begin` (summary / Usage / Env) and `@help-options-begin` (every flag, including `-h/--help`).
- Help text is English.
- GPU / Accelerate: `shell_script/mc-run-python.sh`. 
- File pull: `shell_script/file_sync/r2l.sh` (dry-run by default).
- When adding Slurm batch scripts, submit from the repo root and source `shell_script/hpc/env.sh` (`PROJECT_ROOT` is `SLURM_SUBMIT_DIR`, not `BASH_SOURCE`). Sync dependencies on the login node.
- Do not commit SMTP secrets; keep them in gitignored `shell_script/env_email.sh`.

## Hydra, artifacts, and training

- Compose configs under `configs/hydra`.
- Use `@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")`.
- Hydra `run.dir` and `sweep.dir` (see `configs/hydra/hydra/default.yaml`), checkpoints, and logs live under `artifacts/`.
- Do not commit `artifacts/`, datasets, `.env`, or secret scripts.