# __PROJECT_NAME__

```bash
uv sync
uv run python -m __PACKAGE_NAME__.cli --help
uv run pytest
uv run ruff check
uv run ty check
```

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
