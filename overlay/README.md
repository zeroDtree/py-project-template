# __PROJECT_NAME__

```bash
uv sync
uv run python -m __PACKAGE_NAME__.cli --help
uv run pytest
bash shell_script/mc-run-python.sh __PACKAGE_NAME__.cli
```

Importable code lives in `src/__PACKAGE_NAME__`. Configuration is under `configs`. Runtime outputs are written beneath `artifacts`.

See [docs/best-practices.md](docs/best-practices.md) for project conventions.
