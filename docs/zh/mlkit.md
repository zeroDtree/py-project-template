# mlkit

`--mlkit` 默认关闭。它把钉住的 [my_pkg_py](https://github.com/zeroDtree/my_pkg_py) 放进项目，并把 Hydra 入口换成这个库的训练流水线。

```bash
git submodule update --init my_pkg_py
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
```

新克隆的 `origin` 要用 HTTPS 时加上 `--https`。模板本身就是用 HTTP 或 HTTPS 克隆的话，也会自动改写。见 [init.sh](init.md)。

## 项目里会多出什么

- `pkgs/my_pkg_py` 是子模块检出的 git 克隆。`init.sh` 会把克隆的 `HEAD` 和子模块提交比对，不一致就退出。`pkgs/` 被 gitignore，所以这个 pin 记在模板仓库里，不在新项目的历史里。
- `overlay_mlkit/` 覆盖在基础 overlay 之上。这会加入 `train.py`、`data.py`、`model.py`、`utils_for_main.py`，以及模型、数据集、优化器和 W&B 的 Hydra 配置。
- `scaffold.py` 追加 `mlkit` 依赖和 uv 的 path source，并在 `README.md` 末尾加上一段 mlkit 说明。

```toml
[tool.uv.sources]
mlkit = { path = "pkgs/my_pkg_py", editable = true }
```

导入名是 `mlkit`。在你自己移动它之前，检出停留在本模板子模块记录的那次提交。

## `train.run` 做什么

`cli.py` 调用 `run(cfg)`，不再打印配置。

每个进程上，`run` 用 `cfg.train.seed` 设定随机种子，并用 `cfg.train.mixed_precision` 创建 `Accelerator`。本地主进程创建 `cfg.log.log_dir`，把解析后的配置写进日志，并用 `wandb` 配置组调用 `wandb.init`（`mode` 默认 `offline`，`project` 是项目名）。

然后它按 Hydra 的分组构建模型、数据集、优化器和学习率调度器，并通过 `mlkit.pipeline` 训练。训练结束后，主进程调用 `wandb.finish()`。

`src/my_exp/model.py` 是一个玩具线性模块，`forward` 返回带 `loss` 的字典。实验是真的时候，换掉 `get_model` 和 `get_dataset`。把 `pkgs/my_pkg_py` 当作依赖的库，而不是要改的源码，除非你就是要改这个 pin。

GPU 训练用 Accelerate 启动脚本：

```bash
bash shell_script/mc-run-python.sh my_exp.cli
```

## 改成依赖 GitHub，而不是本地克隆

不再使用本地检出时，把 `pyproject.toml` 里的 `mlkit` path source 换成 `git+https://github.com/zeroDtree/my_pkg_py`。
