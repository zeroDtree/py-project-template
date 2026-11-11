

## mlkit training

This project uses the `mlkit` training pipeline from the `pkgs/my_pkg_py` submodule (uv editable). The pinned commit is recorded in this repository.

```bash
uv sync
uv run python -m {package}.cli
bash shell_script/mc-run-python.sh {package}.cli
```

If that clone has no submodule checkout, run `git submodule update --init pkgs/my_pkg_py` before `uv sync`.
