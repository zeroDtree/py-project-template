# mlkit

`--mlkit` 放进一份钉住的 [my_pkg_py](https://github.com/zeroDtree/my_pkg_py)，Hydra 入口改走这个库的训练流水线。

```bash
git submodule update --init my_pkg_py
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

新克隆的 `origin` 要走 HTTPS 就加 `--https`。模板本身是用 HTTP 或 HTTPS 克隆的，也会改写。见 [init.sh](init.md)。

## 文件

- `pkgs/my_pkg_py` 是新项目的 submodule。`init.sh` 把检出 detach 到模板 pin，提交对不上就退出。pin 是这个仓库的 gitlink。`pkgs/` 下其它路径仍在 gitignore 里。
- `overlay_mlkit/` 盖在基础 overlay 上，带上 `train.py`、`data.py`、`model.py`、`utils_for_main.py`，以及模型、数据集、优化器和 W&B 的 Hydra 配置。
- `scaffold.py` 补上 `mlkit` 依赖和 uv 的 path source，把 submodule 路径从 gitignore 里放开，并在 `README.md` 末尾加一段说明。

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/my_pkg_py", editable = true }
```

导入名是 `mlkit`。检出停在 init 时本模板子模块记录的那次提交。这次提交就是新项目的 gitlink。

## 训练

`cli.py` 调用 `run(cfg)`。

每个进程用 `cfg.train.seed` 设种子，并用 `cfg.train.mixed_precision` 建 `Accelerator`。本机主进程创建 `cfg.log.log_dir`，把解析后的配置写进日志，再按 `wandb` 配置组调用 `wandb.init`（`mode` 默认 `offline`，`project` 是项目名）。

然后按 Hydra 分组建模型、数据集、优化器和学习率调度器，经 `mlkit.pipeline` 训练。训练结束，主进程调用 `wandb.finish()`。

`src/my_exp/model.py` 是个线性小例子，`forward` 返回带 `loss` 的字典。正式实验换掉 `get_model` 和 `get_dataset`。`pkgs/my_pkg_py` 就是这份 pin 对应的库。

GPU 训练：

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## GitHub

`.gitmodules` 记下 `my_pkg_py` 的 URL，index 记下钉住的提交。第一次提交带上 `.gitmodules` 和 `pkgs/my_pkg_py`，再 push。GitHub 上会显示这个 submodule 和对应 commit。

别人克隆实验仓库时带上 submodule，再同步依赖：

```bash
git clone --recurse-submodules <实验仓库>
uv sync
```

`uv sync` 安装的是磁盘上已经有的可编辑检出。先用 `git clone --recurse-submodules` 把 `pkgs/my_pkg_py` 检出；clone 时没带上的话，先跑 `git submodule update --init pkgs/my_pkg_py`，再跑 `uv sync`。
