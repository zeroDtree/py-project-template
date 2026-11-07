# mlkit

`--mlkit` is off by default. It vendors a pinned copy of [my_pkg_py](https://github.com/zeroDtree/my_pkg_py) and switches the Hydra entrypoint over to that library's training pipeline.

```bash
git submodule update --init my_pkg_py
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

Pass `--https` when the new clone's `origin` should be HTTPS. The flag is also implied when this template was itself cloned over HTTP or HTTPS. See [init.sh](init.md).

## What lands in the project

- `pkgs/my_pkg_py` is a git clone of the submodule checkout. `init.sh` compares the clone's `HEAD` to the submodule commit and exits if they differ. `pkgs/` is gitignored, so the pin lives in the template repo, not in the new project's history.
- `overlay_mlkit/` is copied over the base overlay. That adds `train.py`, `data.py`, `model.py`, `utils_for_main.py`, and Hydra configs for the model, dataset, optimizer, and W&B.
- `scaffold.py` appends an `mlkit` dependency and a uv path source, then appends a short mlkit section to `README.md`.

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/my_pkg_py", editable = true }
```

The import name is `mlkit`. The checkout stays on the commit recorded by this template's submodule until you move it.

## What `train.run` does

`cli.py` calls `run(cfg)` instead of printing the config.

On every process, `run` seeds with `cfg.train.seed` and builds an `Accelerator` from `cfg.train.mixed_precision`. The local main process creates `cfg.log.log_dir`, writes the resolved config to that logger, and calls `wandb.init` with the `wandb` group (`mode` defaults to `offline`, and `project` is the project name).

It then builds the model, datasets, optimizer, and learning-rate scheduler from the Hydra groups, and trains through `mlkit.pipeline`. The main process calls `wandb.finish()` after training.

`src/my_exp/model.py` is a toy linear module whose forward returns a dict with `loss`. Replace `get_model` and `get_dataset` when the experiment is real. Treat `pkgs/my_pkg_py` as the library you depend on, not as a tree to edit, unless you mean to change that pin.

Launch GPU training with the Accelerate runner:

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## Depend on GitHub instead of the clone

To drop the local checkout, replace the `mlkit` path source in `pyproject.toml` with `git+https://github.com/zeroDtree/my_pkg_py`.
