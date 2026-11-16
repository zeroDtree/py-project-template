# mlkit

`--mlkit` vendors a pinned copy of [mlkit](https://github.com/zeroDtree/mlkit) and switches the Hydra entrypoint over to that library's experiment runner.

```bash
git submodule update --init mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

Pass `--https` when the new clone's `origin` should be HTTPS. The flag is also applied when this template was itself cloned over HTTP or HTTPS. See [init.sh](init.md).

## Files

- `pkgs/mlkit` is a submodule of the new project. `init.sh` detaches the checkout at the template pin and exits if that commit does not match. The pin is this repository's gitlink. Other paths under `pkgs/` stay gitignored.
- `overlay_mlkit/` is copied over the base overlay. That adds `train.py`, `data.py`, `model.py`, Hydra configs for the model, dataset, optimizer, W&B, and MLflow, plus the top-level `reporter` switch.
- `scaffold.py` appends an `mlkit` dependency and a uv path source, un-ignores the submodule path, and appends a short mlkit section to `README.md`.

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/mlkit", editable = true }
```

The import name is `mlkit`. The checkout stays on the commit this template's submodule records at init time. That commit is the new project's gitlink.

## Training

`cli.py` calls `run(cfg)`, which passes the module-level `SPEC` to `mlkit.util.experiment.run_experiment`.

The runner seeds from `cfg.train.seed` and builds the session `Accelerator` from `cfg.train.mixed_precision`. On the main process it opens a timestamped log directory under `cfg.log.log_dir` and opens the tracking backend selected by `cfg.reporter`: `none`, `wandb`, or `mlflow`. The matching `wandb` or `mlflow` config section supplies the backend settings. The default is `wandb` with `mode: offline` and `project` set to the project name; W&B writes its `wandb/` directory under the launch directory unless `WANDB_DIR` is set.

`TrainSpec` builds the model, datasets, optimizer, and scheduler, then trains through `mlkit.pipeline`. Checkpoints carry the resolved `config.yaml` and, when tracking is enabled, the tracked run id, so a later run resumes the same experiment. The runner also tears down the process group; `train.py` does not create an `Accelerator`, call `wandb.init`, or destroy the process group itself.

`log.log_dir` and `train.save_dir` resolve relative to the launch directory. Run from the project root (the shell scripts do) so artifacts stay under `artifacts/`.

`src/my_exp/model.py` is a toy linear module whose forward returns a dict with `loss`. Replace `get_model` and `get_dataset` when the experiment is real. Add `after_train`, `on_finish`, or a `get_optimizer` override to `SPEC` when the experiment needs them. `pkgs/mlkit` is the pinned library.

Launch GPU training with the Accelerate runner:

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## GitHub

`.gitmodules` records the `mlkit` URL, and the index records the pinned commit. Include `.gitmodules` and `pkgs/mlkit` in the first commit, then push. GitHub shows the submodule at that commit.

Collaborators clone the experiment repository with submodules, then sync:

```bash
git clone --recurse-submodules <experiment-repo>
uv sync
```

`uv sync` installs the editable checkout that is already on disk. Populate `pkgs/mlkit` with `git clone --recurse-submodules`, or with `git submodule update --init pkgs/mlkit` when the clone omitted it, before running `uv sync`.
