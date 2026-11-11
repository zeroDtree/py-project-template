# Conventions

A generated project's `docs/best-practices.md` is the English copy of these rules.

## Language

Identifiers, comments, docstrings, CLI help, and commit messages are in English.

## Layout

| Path | Role |
| --- | --- |
| `src/my_exp` | Importable package (Hatch `src` layout). |
| `configs/` | Hydra (`configs/hydra`) and Accelerate configuration. |
| `tests/` | pytest, mirrored to the package layout. |
| `artifacts/` | Runtime outputs: Hydra runs, checkpoints, logs. |
| `docs/` | Design notes and math write-ups for that project. |
| `legacy/` | Optional later directory for historical code. Excluded from Ruff and ty. |
| `pkgs/` | Optional third-party or workspace packages. `--mlkit` registers the pinned `my_pkg_py` submodule at `pkgs/my_pkg_py`. Other paths under `pkgs/` stay gitignored. Treat the submodule as a reference unless you were asked to edit it. |
| `data/` | Optional later directory for datasets and other inputs. Gitignored. Under it: `raw/`, `meta/`, and `processed/`. Rules are in the generated project's `docs/best-practices.md`. |

The repo root is the directory that holds `.project-root`. `paths.py` reads it from there.

## Environment

Use Python 3.12 unless `--python` said otherwise. Use uv.

One-off commands go through `uv run`. An interactive session may `source .venv/bin/activate`. The package is private (`Private :: Do Not Upload`).

## Checks

Before Python work is finished:

```bash
uv run ruff check
uv run ty check
```

Fix failures and run both again. Auto-fix with `uv run ruff check --fix`, then `uv run ruff format`.

Prefer `from __future__ import annotations`, `X | None`, and frozen dataclasses for config objects. Details of the Ruff and ty configs are on the [Quality checks](quality.md) page.

## Shell scripts

Invoke `bash shell_script/...` from the project root. Scripts use `set -euo pipefail`. Help text is English, with `@help-begin` for the summary and `@help-options-begin` for every flag, including `-h` / `--help`.

GPU work goes through `shell_script/mc-run-python.sh`. CPU work goes through `shell_script/run-python.sh`. File pull is `shell_script/file_sync/r2l.sh`, dry-run unless you pass `--run`. Slurm batch scripts should be submitted from the repo root and should source `shell_script/hpc/env.sh`. Sync dependencies on the login node.

SMTP secrets stay in gitignored `shell_script/env_email.sh`. Do not commit the password.

## Hydra and training

Compose configs under `configs/hydra`. The entrypoint uses `@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")`.

Hydra run and sweep directories, checkpoints, and logs live under `artifacts/`. With `--mlkit`, training goes through `mlkit.pipeline`. `pkgs/my_pkg_py` is a submodule pinned to the template commit. Collaborators clone with `--recurse-submodules`.

Leave `artifacts/`, datasets, `.env`, and secret scripts out of git.
