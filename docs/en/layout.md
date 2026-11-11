# Layout

After `./init.sh --dest /path/to/my-exp --name my-exp`, the new project looks like this:

```text
my-exp/
├── src/my_exp/                 # importable package (Hatch src layout)
│   ├── __init__.py
│   ├── cli.py                  # Hydra entrypoint
│   └── paths.py                # PROJECT_ROOT / configs / artifacts via .project-root
├── configs/
│   ├── hydra/                  # Hydra compose configs (train, log, run dirs)
│   └── accelerate/             # Accelerate launch config
├── tests/                      # pytest, mirrored to the package layout
├── docs/                       # conventions and notes
├── shell_script/               # CPU / GPU runners, email, file sync, HPC helpers
│   ├── run-python.sh
│   ├── mc-run-python.sh
│   ├── file_sync/
│   └── hpc/
├── artifacts/                  # runtime outputs (gitignored; created on run)
├── pyproject.toml
├── ruff.toml
├── ty.toml
├── .project-root
├── .python-version
└── README.md
```

Runners and Hydra create `artifacts/` when something writes output.

## Paths

| Path | Role |
| --- | --- |
| `src/my_exp` | Importable package. Hatch builds from this `src` layout. |
| `configs/` | Hydra files under `configs/hydra`, Accelerate file under `configs/accelerate`. |
| `tests/` | pytest. The sample test imports the package and checks `paths.py`. |
| `docs/` | Design notes for that project. `init.sh` puts `docs/best-practices.md` here. |
| `shell_script/` | Runners, email, file sync, and one Slurm helper. Invoke them from the project root. |
| `artifacts/` | Hydra runs, checkpoints, logs, and command logs. Gitignored. |
| `.project-root` | Marker file. `paths.py` walks parents until it finds this file. |
| `.python-version` | The `--python` version, for uv. |

## `--mlkit` and `--lorebook`

`--mlkit` merges `overlay_mlkit/` and clones the library:

- `src/my_exp/train.py`, `data.py`, `model.py`, and `utils_for_main.py` join the package. `cli.py` then calls `train.run`.
- `configs/hydra/` gains `model/`, `dataset/`, `optimizer/`, and `wandb/`.
- `pkgs/my_pkg_py` is a submodule pinned to the template submodule's commit at init. The pin is stored in the new project. Other paths under `pkgs/` stay gitignored.

`--lorebook` copies editor rules.

- `.cursor/` for Cursor rules and skills
- `.github/instructions/` for Copilot
- `.claude/rules/` for Claude

Those three paths are gitignored by the generated `.gitignore`.

## Later

Add these yourself. The generated Ruff and ty configs already ignore the first two when they appear.

| Path | Role |
| --- | --- |
| `legacy/` | Historical code. Excluded from Ruff and ty. Not gitignored. |
| `pkgs/` | Third-party or workspace packages. Gitignored. `--mlkit` registers `pkgs/my_pkg_py` as a submodule and tracks that path. |
| `data/` | Datasets and other inputs. Gitignored. Do not commit it. Under it: `raw/`, `meta/`, and `processed/`. Rules are in the generated project's `docs/best-practices.md`. |
