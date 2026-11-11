

## mlkit training

This project uses the `mlkit` training pipeline from `pkgs/my_pkg_py` (uv editable), cloned at this template's submodule commit. That clone is gitignored.

```bash
uv sync
uv run python -m {package}.cli
bash shell_script/mc-run-python.sh {package}.cli
```

To depend on GitHub instead of the local clone, replace the `mlkit` path source in `pyproject.toml` with `git+https://github.com/zeroDtree/my_pkg_py`.
