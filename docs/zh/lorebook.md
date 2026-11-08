# Lorebook

`--lorebook` 把 Cursor、Copilot 和 Claude 的规则拷进新项目。

```bash
git submodule update --init ai-lorebook
./init.sh --dest /path/to/my-exp --name my-exp --lorebook
```

占位符换完后，`init.sh` 跑 `ai-lorebook/apply.sh -d DEST -f`。`-f` 覆盖内容不同的文件。找不到 `apply.sh` 就退出，并提示先跑 `git submodule update --init ai-lorebook`。

## 文件

`apply.sh` 复制这三处：

| 目标 | 内容 |
| --- | --- |
| `.cursor/` | Cursor 的规则和技能，包括 `.cursor/rules/` 和 `.cursor/skills/`。 |
| `.github/instructions/` | GitHub Copilot 的说明。 |
| `.claude/rules/` | Claude 的规则。 |

生成的 `.gitignore` 忽略这三处。这是本机编辑器的配置。

同一个脚本也可以只复制一处（`--cursor`、`--copilot`、`--claude`），用 `-n` 看将要写什么，或者不加 `-f`，碰到已有文件就停。`init.sh` 固定复制全部并带上 `-f`。只要其中一部分，自己跑 `apply.sh`。

规则和技能名单以模板钉住的那次提交里、子模块的 `README.md` 为准。
