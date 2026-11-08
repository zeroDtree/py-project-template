# Python environment

Generated projects use uv. Dependencies and commands go through uv, inside the project environment.

## Version pin

`--python` defaults to 3.12. That value is written to `.python-version` and to `requires-python`.

For 3.12 the constraint is:

```text
>=3.12,<3.13
```

The upper bound is the next minor version, so `3.12.8` still produces `>=3.12.8,<3.13` and a Ruff target of `py312`.

The package is marked `Private :: Do Not Upload`.

## Commands

From the new project root:

```bash
uv sync
uv run python -m my_exp.cli --help
uv run pytest
```

`pyproject.toml` also defines a console script named after the project:

```toml
[project.scripts]
my-exp = "my_exp.cli:main"
```

`uv sync` installs the project and the `dev` group. An interactive shell may `source .venv/bin/activate` after that.

Once per clone, register the notebook filter:

```bash
uv run nbstripout --install --attributes .gitattributes
```

Commits then strip notebook cell output. `uv run nbstripout --status` shows whether the filter is installed.

## Dependency groups

| Group | Contains | Used for |
| --- | --- | --- |
| `lint` | pytest, ruff, ty | Tests and the quality commands. |
| `utils` | tqdm, accelerate | Progress output and the GPU launcher. |
| `notebook` | ipykernel, ipywidgets, nbstripout | Notebooks, and stripping cell output on commit. |
| `dev` | the groups above | What `uv sync` installs by default. |

Hydra (`hydra-core`, `omegaconf`) is a project dependency, so it is installed with the package.

## paths.py

The package lives in `src/my_exp`. Hatchling builds that tree:

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/my_exp"]
```

`paths.py` walks from its own file up to the `.project-root` marker and exposes:

| Name | Points at |
| --- | --- |
| `PROJECT_ROOT` | The directory that contains `.project-root`. |
| `CONFIG_ROOT` | `PROJECT_ROOT / "configs"` |
| `HYDRA_CONFIG_ROOT` | `PROJECT_ROOT / "configs" / "hydra"` |
| `ARTIFACT_ROOT` | `PROJECT_ROOT / "artifacts"` |

`project_path("configs/hydra/default.yaml")` joins a relative path onto `PROJECT_ROOT`. An absolute path is returned unchanged. If the marker file is missing, importing the module raises `RuntimeError`.
