# Lorebook

`--lorebook` copies Cursor, Copilot, and Claude rules into the new project.

```bash
git submodule update --init ai-lorebook
./init.sh --dest /path/to/my-exp --name my-exp --lorebook
```

`init.sh` runs `ai-lorebook/apply.sh -d DEST -f` after tokens are replaced. `-f` overwrites files that differ. If `apply.sh` is missing, init exits and tells you to run `git submodule update --init ai-lorebook`.

## Files

`apply.sh` copies all three trees:

| Destination | Contents |
| --- | --- |
| `.cursor/` | Cursor rules and skills, including `.cursor/rules/` and `.cursor/skills/`. |
| `.github/instructions/` | GitHub Copilot instructions. |
| `.claude/rules/` | Claude rules. |

The generated `.gitignore` ignores these three paths. They are local editor policy.

The same script can copy a single tree (`--cursor`, `--copilot`, `--claude`), print a dry run (`-n`), or stop before an overwrite (omit `-f`). `init.sh` always copies every tree and passes `-f`. Run `apply.sh` yourself for a subset.

The rule and skill list is the submodule `README.md` at the commit this template pins.
