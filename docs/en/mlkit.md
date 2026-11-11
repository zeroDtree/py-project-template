# mlkit

`--mlkit` vendors a pinned copy of [my_pkg_py](https://github.com/zeroDtree/my_pkg_py) and switches the Hydra entrypoint over to that library's training pipeline.

```bash
git submodule update --init my_pkg_py
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

Pass `--https` when the new clone's `origin` should be HTTPS. The flag is also applied when this template was itself cloned over HTTP or HTTPS. See [init.sh](init.md).

## Files

- `pkgs/my_pkg_py` is a submodule of the new project. `init.sh` detaches the checkout at the template pin and exits if that commit does not match. The pin is this repository's gitlink. Other paths under `pkgs/` stay gitignored.
- `overlay_mlkit/` is copied over the base overlay. That adds `train.py`, `data.py`, `model.py`, `utils_for_main.py`, and Hydra configs for the model, dataset, optimizer, and W&B.
- `scaffold.py` appends an `mlkit` dependency and a uv path source, un-ignores the submodule path, and appends a short mlkit section to `README.md`.

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/my_pkg_py", editable = true }
```

The import name is `mlkit`. The checkout stays on the commit this template's submodule records at init time. That commit is the new project's gitlink.

## Training

`cli.py` calls `run(cfg)`.

On every process, `run` seeds with `cfg.train.seed` and builds an `Accelerator` from `cfg.train.mixed_precision`. The local main process creates `cfg.log.log_dir`, writes the resolved config to that logger, and calls `wandb.init` with the `wandb` group (`mode` defaults to `offline`, and `project` is the project name).

It then builds the model, datasets, optimizer, and learning-rate scheduler from the Hydra groups, and trains through `mlkit.pipeline`. The main process calls `wandb.finish()` after training.

`src/my_exp/model.py` is a toy linear module whose forward returns a dict with `loss`. Replace `get_model` and `get_dataset` when the experiment is real. `pkgs/my_pkg_py` is the pinned library.

Launch GPU training with the Accelerate runner:

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## GitHub

`.gitmodules` records the `my_pkg_py` URL, and the index records the pinned commit. Include `.gitmodules` and `pkgs/my_pkg_py` in the first commit, then push. GitHub shows the submodule at that commit.

Collaborators clone the experiment repository with submodules, then sync:

```bash
git clone --recurse-submodules <experiment-repo>
uv sync
```

`uv sync` installs the editable checkout that is already on disk. Populate `pkgs/my_pkg_py` with `git clone --recurse-submodules`, or with `git submodule update --init pkgs/my_pkg_py` when the clone omitted it, before running `uv sync`.
