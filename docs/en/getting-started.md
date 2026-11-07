# Getting started

## Prerequisites

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) and git. `init.sh` refuses to run without uv. uv provides Python 3.12 for the template's own helper; you do not install that interpreter yourself.

`--mlkit` and `--lorebook` need the git submodules. A project without those flags does not.

## Clone

```bash
git clone --recurse-submodules git@github.com:zeroDtree/py-project-template.git
cd py-project-template
```

If the clone is already on disk without submodules:

```bash
git submodule update --init my_pkg_py
git submodule update --init ai-lorebook
```

Initialize only the submodule you are about to use.

## Create a project

The destination must not exist, or it must be an empty directory. `--name` defaults to the destination's basename.

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

Then, from the new project:

```bash
cd /path/to/my-exp
uv sync
uv run ruff check
uv run ty check
uv run pytest
uv run python -m my_exp.cli --help
```

`--package` defaults to the project name with `-` replaced by `_`, so `my-exp` imports as `my_exp`.

Optional flags, covered on the [init.sh](init.md) page:

```bash
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook --https
```

## When init stops

!!! failure "uv is missing"

    Install uv and run the command again. The script does not fall back to `python` or `pip`.

!!! failure "Destination is not empty"

    `init.sh` only creates new projects. Pick an empty directory. It will not merge into a repo that already has files.

!!! failure "Submodule is missing"

    `--mlkit` needs `git submodule update --init my_pkg_py`. `--lorebook` needs `git submodule update --init ai-lorebook`.
