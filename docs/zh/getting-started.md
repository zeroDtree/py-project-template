# 快速开始

## 准备

安装 [uv](https://docs.astral.sh/uv/getting-started/installation/) 和 git。找不到 uv 时 `init.sh` 退出。模板里的辅助脚本用 uv 带的 Python 3.12。

`--mlkit` 和 `--lorebook` 依赖 git 子模块。

## 克隆

```bash
git clone --recurse-submodules git@github.com:zeroDtree/py-project-template.git
cd py-project-template
```

仓库已经在本地、克隆时没带子模块：

```bash
git submodule update --init my_pkg_py
git submodule update --init ai-lorebook
```

接下来要用哪个，就初始化哪个。

## 创建项目

路径不存在会建出来。路径已经在，就必须是空目录。`--name` 省略时取目录名的最后一段。

```bash
./init.sh --dest /path/to/my-exp --name my-exp
```

然后：

```bash
cd /path/to/my-exp
uv sync
uv run ruff check
uv run ty check
uv run pytest
uv run python -m my_exp.cli --help
```

`--package` 默认把项目名里的 `-` 换成 `_`。`my-exp` 的导入名是 `my_exp`。

别的参数在 [init.sh](init.md)：

```bash
./init.sh --dest /path/to/my-exp --name my-exp --mlkit
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook
./init.sh --dest /path/to/my-exp --name my-exp --mlkit --lorebook --https
```

## 失败

!!! failure "没有 uv"

    装上 uv 再跑一次。

!!! failure "目标目录不是空的"

    换一个空目录。

!!! failure "子模块还没初始化"

    `--mlkit` 需要 `git submodule update --init my_pkg_py`。`--lorebook` 需要 `git submodule update --init ai-lorebook`。
