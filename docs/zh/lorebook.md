# Lorebook

`--lorebook` 默认关闭。不用它创建的项目没有 `.cursor/`，没有 Copilot 说明，也没有 `.claude/rules/`。

```bash
git submodule update --init ai-lorebook
./init.sh --dest /path/to/my-exp --name my-exp --lorebook
```

`init.sh` 在替换完占位符之后运行 `ai-lorebook/apply.sh -d DEST -f`。`-f` 会覆盖内容不同的文件。找不到 `apply.sh` 时，初始化退出，并提示运行 `git submodule update --init ai-lorebook`。

## 会复制什么

`apply.sh` 不带更窄的参数时，三棵目录都会复制：

| 目标 | 内容 |
| --- | --- |
| `.cursor/` | Cursor 的规则和技能，包括 `.cursor/rules/` 和 `.cursor/skills/`。 |
| `.github/instructions/` | GitHub Copilot 的说明。 |
| `.claude/rules/` | Claude 的规则。 |

生成的 `.gitignore` 忽略这三处。它们是本机的编辑器策略，不是项目源码。

同一个脚本也可以只复制一棵目录（`--cursor`、`--copilot`、`--claude`），只打印将要做什么（`-n`），或者在覆盖前停下来（不加 `-f`）。`init.sh` 不提供这些选择。它总是复制全部，并带上 `-f`。想要子集时，自己运行 `apply.sh`。

规则和技能的清单以本模板钉住的那次提交里的子模块 `README.md` 为准。读那份文件，这里不再列第二份，避免两边以后对不上。
