# Getting started

## Prerequisites

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) and git. `init.sh` exits when uv is missing. uv supplies Python 3.12 for the template's own helper.

`--mlkit` and `--lorebook` need the git submodules.

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

Init the submodule you are about to use.

## Create a project

The destination is created when missing. An existing directory must be empty. `--name` defaults to the destination's basename.

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

Then:

```bash
cd /path/to/my-exp
bash shell_script/init-check.sh
```

Pass `--name` only. The import package replaces `-` and `.` in that name with `_`, so `my-exp` and `my.exp` both import as `my_exp`. Pass `--package` when the import name should differ, for example `--name acme-lab --package lab`.

Other flags are listed on the [init.sh](init.md) page:

```bash
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook --https
```

## Failures

!!! failure "uv is missing"

    Install uv and run the command again.

!!! failure "Destination is not empty"

    Pick an empty directory.

!!! failure "Submodule is missing"

    `--mlkit` needs `git submodule update --init my_pkg_py`. `--lorebook` needs `git submodule update --init ai-lorebook`.
