# Lorebook

`--lorebook` is off by default. A project created without it has no `.cursor/`, no Copilot instructions, and no `.claude/rules/`.

```bash
git submodule update --init ai-lorebook
./init.sh --dest /path/to/my-exp --name my-exp --lorebook
```

`init.sh` runs `ai-lorebook/apply.sh -d DEST -f` after tokens are replaced. `-f` overwrites files that differ. If `apply.sh` is missing, init exits and tells you to run `git submodule update --init ai-lorebook`.

## What gets copied

`apply.sh` without a narrower flag copies all three trees:

| Destination | Contents |
| --- | --- |
| `.cursor/` | Cursor rules and skills, including `.cursor/rules/` and `.cursor/skills/`. |
| `.github/instructions/` | GitHub Copilot instructions. |
| `.claude/rules/` | Claude rules. |

The generated `.gitignore` ignores these three paths. They are local editor policy, not project source.

The same script can copy a single tree (`--cursor`, `--copilot`, `--claude`), print a dry run (`-n`), or stop before an overwrite (omit `-f`). `init.sh` does not expose those choices. It always copies every tree and passes `-f`. Run `apply.sh` yourself when you want a subset.

The rule and skill list is maintained in the submodule's `README.md` at the commit this template pins. Read that file rather than a second list here, so the two cannot drift.
