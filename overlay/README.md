# __PROJECT_NAME__

```bash
git clone --recurse-submodules <this-repo>
```

From the project root, after init or clone:

```bash
bash shell_script/init-check.sh
```

The script runs `uv sync`, which installs the `dev` group, including `notebook`. It checks the CLI and runs pytest, ruff, and ty. It also installs the nbstripout git filter once per clone so commits strip notebook cell output. Check with `uv run nbstripout --status`.

CPU (no Accelerate):

```bash
bash shell_script/run-python.sh __PACKAGE_NAME__.cli
```

GPU-only training / eval with Accelerate (`run-python.sh` for CPU):

```bash
bash shell_script/mc-run-python.sh __PACKAGE_NAME__.cli
```

Importable code lives in `src/__PACKAGE_NAME__`. Configuration is under `configs`. Runtime outputs are written beneath `artifacts`.

See [docs/best-practices.md](docs/best-practices.md) for project conventions and [shell_script/README.md](shell_script/README.md) for runners, email, file sync, and HPC helpers.
