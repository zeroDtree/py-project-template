# 目录结构

`./init.sh --dest /path/to/my-exp --name my-exp` 之后，新项目是这样的：

```text
my-exp/
├── src/my_exp/                 # 可导入的包（Hatch src 布局）
│   ├── __init__.py
│   ├── cli.py                  # Hydra 入口
│   └── paths.py                # 用 .project-root 定位 PROJECT_ROOT / configs / artifacts
├── configs/
│   ├── hydra/                  # Hydra 组合配置（train、log、运行目录）
│   └── accelerate/             # Accelerate 启动配置
├── tests/                      # pytest，与包的布局对应
├── docs/                       # 约定和笔记
├── shell_script/               # CPU / GPU 启动、邮件、文件同步、HPC
│   ├── run-python.sh
│   ├── mc-run-python.sh
│   ├── file_sync/
│   └── hpc/
├── artifacts/                  # 运行产物（gitignore；运行时才创建）
├── pyproject.toml
├── ruff.toml
├── ty.toml
├── .project-root
├── .python-version
└── README.md
```

`init.sh` 不会创建 `artifacts/`。启动脚本或 Hydra 在写出结果时才创建它。

## 每个路径做什么

| 路径 | 作用 |
| --- | --- |
| `src/my_exp` | 可导入的包。Hatch 按这个 `src` 布局构建。 |
| `configs/` | Hydra 在 `configs/hydra`，Accelerate 在 `configs/accelerate`。 |
| `tests/` | pytest。示例测试会导入包并检查 `paths.py`。 |
| `docs/` | 这个项目自己的设计笔记。`init.sh` 会放入 `docs/best-practices.md`。 |
| `shell_script/` | 启动脚本、邮件、文件同步，以及一个 Slurm 辅助脚本。从项目根目录调用。 |
| `artifacts/` | Hydra 运行目录、检查点、日志和命令日志。被 gitignore。 |
| `.project-root` | 标记文件。`paths.py` 向父目录查找，直到看见它。 |
| `.python-version` | `--python` 的版本，给 uv 用。 |

## 参数会多出哪些文件

`--mlkit` 会合并 `overlay_mlkit/` 并克隆库：

- 包里增加 `src/my_exp/train.py`、`data.py`、`model.py`、`utils_for_main.py`。`cli.py` 改为调用 `train.run`。
- `configs/hydra/` 增加 `model/`、`dataset/`、`optimizer/`、`wandb/`。
- `pkgs/my_pkg_py` 是一个 git 克隆，提交钉在模板子模块当前的 commit。新项目的 gitignore 忽略整个 `pkgs/`。

`--lorebook` 只复制编辑器规则，不改 Python 包。

- `.cursor/`：Cursor 的规则和技能
- `.github/instructions/`：Copilot
- `.claude/rules/`：Claude

生成的 `.gitignore` 会忽略这三处。

## 以后可以自己加的目录

`init.sh` 不创建下面这些目录。生成的 Ruff 和 ty 配置已经排除前两个（一旦它们出现）。

| 路径 | 作用 |
| --- | --- |
| `legacy/` | 历史代码。Ruff 和 ty 排除。不在 gitignore 里。 |
| `pkgs/` | 第三方或工作区里的包。被 gitignore。`--mlkit` 是模板准备好的那种用法。 |
| `data/` | 数据集和其他输入。被 gitignore。不要提交。 |
