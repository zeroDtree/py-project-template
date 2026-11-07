# Python 环境

生成的项目用 uv。不要用裸的 `pip` 装依赖，也不要用项目环境以外的系统 `python` 跑这个包。

## 版本约束

`--python` 默认是 3.12。这个值会写进 `.python-version` 和 `requires-python`。

3.12 的约束是：

```text
>=3.12,<3.13
```

上界是下一个次版本，不是下一个补丁。`3.12.8` 得到的仍是 `>=3.12.8,<3.13`，Ruff 的 target 是 `py312`。

包带有分类标记 `Private :: Do Not Upload`。

## 怎么运行

在新项目的根目录：

```bash
uv sync
uv run python -m my_exp.cli --help
uv run pytest
```

`pyproject.toml` 还有一个与项目同名的控制台脚本：

```toml
[project.scripts]
my-exp = "my_exp.cli:main"
```

`uv sync` 会安装项目本身和 `dev` 组。装完之后，交互式 shell 可以 `source .venv/bin/activate`。

## 依赖组

| 组 | 内容 | 用途 |
| --- | --- | --- |
| `lint` | pytest、ruff、ty | 测试和质量检查。 |
| `utils` | tqdm、accelerate | 进度输出和 GPU 启动器。 |
| `dev` | 上面两组 | `uv sync` 默认会装的内容。 |

Hydra（`hydra-core`、`omegaconf`）是项目依赖，不是某个组，会随包一起安装。

## 布局和路径

包在 `src/my_exp`。Hatchling 构建的就是这棵树：

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/my_exp"]
```

文件位置相对于仓库，而不是进程的当前目录。`paths.py` 从自己的文件向上找到 `.project-root`，然后给出：

| 名称 | 指向 |
| --- | --- |
| `PROJECT_ROOT` | 含有 `.project-root` 的目录。 |
| `CONFIG_ROOT` | `PROJECT_ROOT / "configs"` |
| `HYDRA_CONFIG_ROOT` | `PROJECT_ROOT / "configs" / "hydra"` |
| `ARTIFACT_ROOT` | `PROJECT_ROOT / "artifacts"` |

`project_path("configs/hydra/default.yaml")` 把相对路径接到 `PROJECT_ROOT` 上。绝对路径原样返回。找不到标记文件时，导入这个模块会抛出 `RuntimeError`。
