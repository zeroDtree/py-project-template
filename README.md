# Python project template

Scaffold a new Python / ML-research repo with uv, Ruff, ty, Hydra, and an `artifacts/` layout.

This template **only initializes new projects**. It will refuse a non-empty destination. **uv** is required to run `init.sh`; it provides Python 3.12.

## Usage

Clone the repository:
```bash
git clone --recurse-submodules git@github.com:zeroDtree/py-project-template.git
cd py-project-template
```

Initialize a new project:
```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

Default init does not copy AI rules. Pass `--lorebook` to run `ai-lorebook/apply.sh`.

To include the `mlkit` training pipeline, pass `--mlkit`. That clones this repo's pinned `my_pkg_py` submodule into `pkgs/my_pkg_py` (gitignored). Use `--https` to set that clone's origin to HTTPS (also automatic when this template's `origin` is already HTTPS).

```bash
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --https --lorebook
```

## Template Structure

This repository:

```text
.
├── init.sh            # scaffold a new project (destination must be empty)
├── scaffold.py        # token replace, HTTPS URLs, pyproject TOML edit
├── pyproject.toml     # uv project for the template itself (Python 3.12)
├── uv.lock
├── overlay/           # copied into the destination; placeholders are then replaced
├── overlay_mlkit/     # merged when --mlkit
├── my_pkg_py/         # submodule; pinned mlkit source used by --mlkit
├── ai-lorebook/       # submodule; --lorebook copies Cursor / Copilot / Claude rules
└── tests/             # scaffold unit tests and golden init
```

After `./init.sh --dest /path/to/my-exp --name my-exp`, the new project looks like:
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
├── pyproject.toml              # uv, Hatch, pytest, dependency groups
├── ruff.toml
├── ty.toml
├── .project-root               # marker used by paths.py
├── .python-version
└── README.md
```

`--package` defaults to the project name with `-` replaced by `_` (`my-exp` → `my_exp`). Optional later dirs: `legacy/` (historical code) and `pkgs/` (third-party / workspace packages); both are excluded from Ruff and ty if present. `--mlkit` clones the pinned `my_pkg_py` submodule into `pkgs/` (gitignored in the new project).
