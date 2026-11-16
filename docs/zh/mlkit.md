# mlkit

`--mlkit` 放进一份钉住的 [mlkit](https://github.com/zeroDtree/mlkit)，Hydra 入口改走这个库的实验入口。

```bash
git submodule update --init mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

新克隆的 `origin` 要走 HTTPS 就加 `--https`。模板本身是用 HTTP 或 HTTPS 克隆的，也会改写。见 [init.sh](init.md)。

## 文件

- `pkgs/mlkit` 是新项目的 submodule。`init.sh` 把检出 detach 到模板 pin，提交对不上就退出。pin 是这个仓库的 gitlink。`pkgs/` 下其它路径仍在 gitignore 里。
- `overlay_mlkit/` 盖在基础 overlay 上，带上 `train.py`、`data.py`、`model.py`，以及模型、数据集、优化器、W&B 和 MLflow 的 Hydra 配置，还有顶层的 `reporter` 开关。
- `scaffold.py` 补上 `mlkit` 依赖和 uv 的 path source，把 submodule 路径从 gitignore 里放开，并在 `README.md` 末尾加一段说明。

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/mlkit", editable = true }
```

导入名是 `mlkit`。检出停在 init 时本模板子模块记录的那次提交。这次提交就是新项目的 gitlink。

## 训练

`cli.py` 调用 `run(cfg)`，后者把模块级 `SPEC` 交给 `mlkit.util.experiment.run_experiment`。

runner 用 `cfg.train.seed` 设种子，并按 `cfg.train.mixed_precision` 建会话 `Accelerator`。主进程在 `cfg.log.log_dir` 下打开带时间戳的日志目录，再按 `cfg.reporter` 打开追踪后端：`none`、`wandb` 或 `mlflow`。对应的 `wandb` / `mlflow` 配置组提供后端参数。默认是 `wandb`，`mode: offline`，`project` 是项目名；未设置 `WANDB_DIR` 时，W&B 在启动目录下写 `wandb/`。

`TrainSpec` 按 Hydra 分组建模型、数据集、优化器和学习率调度器，经 `mlkit.pipeline` 训练。检查点里会写入解析后的 `config.yaml`；开启追踪时还会记录 run id，后续训练据此续上同一个实验。进程组也由 runner 拆除；`train.py` 不再自己建 `Accelerator`、调用 `wandb.init` 或销毁进程组。

`log.log_dir` 和 `train.save_dir` 相对启动目录解析。从项目根启动（shell 脚本就是这么做的），产物才会落在 `artifacts/`。

`src/my_exp/model.py` 是个线性小例子，`forward` 返回带 `loss` 的字典。正式实验换掉 `get_model` 和 `get_dataset`；需要时给 `SPEC` 加 `after_train`、`on_finish` 或自定义 `get_optimizer`。`pkgs/mlkit` 就是这份 pin 对应的库。

GPU 训练：

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## GitHub

`.gitmodules` 记下 `mlkit` 的 URL，index 记下钉住的提交。第一次提交带上 `.gitmodules` 和 `pkgs/mlkit`，再 push。GitHub 上会显示这个 submodule 和对应 commit。

别人克隆实验仓库时带上 submodule，再同步依赖：

```bash
git clone --recurse-submodules <实验仓库>
uv sync
```

`uv sync` 安装的是磁盘上已经有的可编辑检出。先用 `git clone --recurse-submodules` 把 `pkgs/mlkit` 检出；clone 时没带上的话，先跑 `git submodule update --init pkgs/mlkit`，再跑 `uv sync`。
