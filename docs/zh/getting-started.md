# 快速开始

## 准备

安装 [uv](https://docs.astral.sh/uv/getting-started/installation/) 和 git。没有 uv 时 `init.sh` 直接退出。模板自己的辅助脚本用的 Python 3.12 由 uv 提供，不用另外装解释器。

只有 `--mlkit` 和 `--lorebook` 需要 git 子模块。不用这两个参数时，可以不初始化子模块。

## 克隆

```bash
git clone --recurse-submodules git@github.com:zeroDtree/py-project-template.git
cd py-project-template
```

仓库已经在本地、但当时没带子模块时：

```bash
git submodule update --init my_pkg_py
git submodule update --init ai-lorebook
```

只初始化你马上要用的那一个即可。

## 创建项目

目标路径可以不存在，也可以是空目录。`--name` 省略时，用目标目录的最后一段作为项目名。

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

然后进入新项目：

```bash
cd /path/to/my-exp
uv sync
uv run ruff check
uv run ty check
uv run pytest
uv run python -m my_exp.cli --help
```

`--package` 的默认值是把项目名里的 `-` 换成 `_`。`my-exp` 的导入名是 `my_exp`。

可选参数在 [init.sh](init.md) 一页有完整说明：

```bash
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook --https
```

## 初始化失败时

!!! failure "没有 uv"

    装好 uv 再运行。脚本不会改用系统里的 `python` 或 `pip`。

!!! failure "目标目录不是空的"

    `init.sh` 只创建新项目。换一个空目录。它不会往已有文件的仓库里合并。

!!! failure "子模块还没初始化"

    `--mlkit` 需要 `git submodule update --init my_pkg_py`。`--lorebook` 需要 `git submodule update --init ai-lorebook`。
