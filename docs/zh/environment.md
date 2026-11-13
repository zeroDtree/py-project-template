# Python 环境

生成的项目用 uv 管依赖和命令，都在项目自己的环境里。

## 版本约束

`--python` 默认 3.12，写进 `.python-version` 和 `requires-python`。

3.12 的约束是：

```text
>=3.12,<3.13
```

上界取下一个次版本。`3.12.8` 得到 `>=3.12.8,<3.13`，Ruff target 是 `py312`。

包的分类是 `Private :: Do Not Upload`。

## 命令

在新项目根目录：

```bash
uv sync
uv run python -m my_exp.cli --help
uv run pytest
```

`pyproject.toml` 里还有一个同名的控制台脚本：

```toml
[project.scripts]
"my-exp" = "my_exp.cli:main"
```

`uv sync` 安装项目和 `dev` 组。之后交互式 shell 可以 `source .venv/bin/activate`。

每个克隆跑一次，把 notebook 过滤器写进 git：

```bash
uv run nbstripout --install --attributes .gitattributes
```

之后提交会去掉 notebook 里的输出。`uv run nbstripout --status` 看过滤器在不在。

## 依赖组

| 组 | 内容 | 用途 |
| --- | --- | --- |
| `lint` | pytest、ruff、ty | 测试和质量检查。 |
| `utils` | tqdm、accelerate | 进度输出和 GPU 启动器。 |
| `notebook` | ipykernel、ipywidgets、nbstripout | 笔记本，以及提交时去掉单元格输出。 |
| `dev` | 上面各组 | `uv sync` 默认会装的内容。 |

Hydra（`hydra-core`、`omegaconf`）算项目依赖，跟包装在一起。

## paths.py

包在 `src/my_exp`。Hatchling 打的就是这棵树：

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/my_exp"]
```

`paths.py` 从自己的文件往上找 `.project-root`，然后给出：

| 名称 | 指向 |
| --- | --- |
| `PROJECT_ROOT` | 含有 `.project-root` 的目录。 |
| `CONFIG_ROOT` | `PROJECT_ROOT / "configs"` |
| `HYDRA_CONFIG_ROOT` | `PROJECT_ROOT / "configs" / "hydra"` |
| `ARTIFACT_ROOT` | `PROJECT_ROOT / "artifacts"` |

`project_path("configs/hydra/default.yaml")` 把相对路径接到 `PROJECT_ROOT` 后面。传绝对路径就原样返回。找不到标记文件时，导入会抛 `RuntimeError`。

导入 `paths.py` 时还会调用 `ensure_repo_on_sys_path()`：若 `sys.path` 里还没有 `PROJECT_ROOT`，就把它插到最前面。控制台脚本不会把当前工作目录放进 `sys.path`；pytest 会，靠的是 `pythonpath = ["src", "."]`。这样脚本才能导入 `pkgs/` 里带进来的代码。
