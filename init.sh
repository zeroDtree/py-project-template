#!/usr/bin/env bash

# @help-begin
# Initialize a new Python project from this template.
#
# Usage:
#   ./init.sh --dest PATH [--name NAME] [--package PKG] [--python VERSION] [--mlkit]
#
# This script only creates new projects. The destination must not exist,
# or must be an empty directory.
#
# --mlkit clones my_pkg_py into pkgs/ (default remote branch) and scaffolds
# the mlkit training pipeline. GitHub access is required.
#
# After overlay copy, this script applies AI rules from ai-lorebook/apply.sh.
# After init, install dependencies from the new project root:
#   cd PATH && uv sync
# @help-end

# @help-options-begin
#   --dest PATH             destination directory for the new project (required)
#   --name NAME             project name (default: destination basename)
#   --package PKG           import package name (default: NAME with '-' -> '_')
#   --python VERSION        Python version (default: 3.12)
#   --mlkit                 clone my_pkg_py into pkgs/ and scaffold the mlkit training pipeline
#   --no-git                skip git init in the destination
#   -h, --help              show help
# @help-options-end

set -euo pipefail

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY="$TEMPLATE_ROOT/overlay"
OVERLAY_MLKIT="$TEMPLATE_ROOT/overlay_mlkit"
DEFAULT_MLKIT_URL="git@github.com:zeroDtree/my_pkg_py.git"

usage() {
	awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0"
	printf '%s\n' '#' 'Options:' '#'
	awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0"
	exit 0
}

[[ $# -ge 1 ]] || usage
case "${1:-}" in
	-h|--help) usage ;;
esac

DEST=""
NAME=""
PACKAGE=""
PYTHON_VERSION="3.12"
NO_GIT=0
USE_MLKIT=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|--help)
			usage
			;;
		--dest)
			[[ $# -ge 2 ]] || { echo "Error: --dest requires a path" >&2; exit 1; }
			DEST="$2"
			shift 2
			;;
		--name)
			[[ $# -ge 2 ]] || { echo "Error: --name requires a value" >&2; exit 1; }
			NAME="$2"
			shift 2
			;;
		--package)
			[[ $# -ge 2 ]] || { echo "Error: --package requires a value" >&2; exit 1; }
			PACKAGE="$2"
			shift 2
			;;
		--python)
			[[ $# -ge 2 ]] || { echo "Error: --python requires a version" >&2; exit 1; }
			PYTHON_VERSION="$2"
			shift 2
			;;
		--mlkit)
			USE_MLKIT=1
			shift
			;;
		--no-git)
			NO_GIT=1
			shift
			;;
		*)
			echo "Error: unknown argument: $1" >&2
			exit 1
			;;
	esac
done

if [[ -z "$DEST" ]]; then
	echo "Error: --dest is required" >&2
	exit 1
fi

DEST="$(mkdir -p "$(dirname "$DEST")" && cd "$(dirname "$DEST")" && pwd)/$(basename "$DEST")"

if [[ -e "$DEST" ]]; then
	if [[ ! -d "$DEST" ]]; then
		echo "Error: destination exists and is not a directory: $DEST" >&2
		exit 1
	fi
	if [[ -n "$(ls -A "$DEST")" ]]; then
		echo "Error: destination is not empty: $DEST" >&2
		echo "init.sh only initializes new projects." >&2
		exit 1
	fi
else
	mkdir -p "$DEST"
fi

if [[ -z "$NAME" ]]; then
	NAME="$(basename "$DEST")"
fi
if [[ -z "$PACKAGE" ]]; then
	PACKAGE="${NAME//-/_}"
fi

if [[ ! "$NAME" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
	echo "Error: invalid project name: $NAME" >&2
	exit 1
fi
if [[ ! "$PACKAGE" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
	echo "Error: invalid package name: $PACKAGE" >&2
	exit 1
fi
if [[ ! "$PYTHON_VERSION" =~ ^[0-9]+\.[0-9]+([.][0-9]+)?$ ]]; then
	echo "Error: invalid Python version: $PYTHON_VERSION" >&2
	exit 1
fi

PYTHON_MAJOR="${PYTHON_VERSION%%.*}"
PYTHON_REST="${PYTHON_VERSION#*.}"
PYTHON_MINOR="${PYTHON_REST%%.*}"
PYTHON_TAG="py${PYTHON_MAJOR}${PYTHON_MINOR}"
PYTHON_NEXT="${PYTHON_MAJOR}.$((PYTHON_MINOR + 1))"

if [[ ! -d "$OVERLAY" ]]; then
	echo "Error: overlay directory is missing: $OVERLAY" >&2
	exit 1
fi

mlkit_url() {
	local url
	url="$(git -C "$TEMPLATE_ROOT" config --file "$TEMPLATE_ROOT/.gitmodules" --get submodule.my_pkg_py.url 2>/dev/null || true)"
	printf '%s\n' "${url:-$DEFAULT_MLKIT_URL}"
}

clone_mlkit() {
	local url
	if [[ ! -d "$OVERLAY_MLKIT" ]]; then
		echo "Error: overlay_mlkit directory is missing: $OVERLAY_MLKIT" >&2
		exit 1
	fi
	url="$(mlkit_url)"
	mkdir -p "$DEST/pkgs"
	git clone "$url" "$DEST/pkgs/my_pkg_py"
	cp -a "$OVERLAY_MLKIT/." "$DEST/"
}

cp -a "$OVERLAY/." "$DEST/"

if [[ "$USE_MLKIT" -eq 1 ]]; then
	clone_mlkit
fi

PACKAGE_SRC="$DEST/src/__PACKAGE_NAME__"
if [[ -d "$PACKAGE_SRC" ]]; then
	mv "$PACKAGE_SRC" "$DEST/src/$PACKAGE"
fi

export DEST PROJECT_NAME="$NAME" PACKAGE_NAME="$PACKAGE" PYTHON_VERSION PYTHON_TAG PYTHON_NEXT USE_MLKIT
python3 - <<'PY'
import os
from pathlib import Path

dest = Path(os.environ["DEST"])
use_mlkit = os.environ.get("USE_MLKIT") == "1"
replacements = {
    "__PROJECT_NAME__": os.environ["PROJECT_NAME"],
    "__PACKAGE_NAME__": os.environ["PACKAGE_NAME"],
    "__PYTHON_VERSION__": os.environ["PYTHON_VERSION"],
    "__PYTHON_TAG__": os.environ["PYTHON_TAG"],
    "__PYTHON_NEXT__": os.environ["PYTHON_NEXT"],
}
skip_dirs = {".git", ".venv", "__pycache__"}
if use_mlkit:
    skip_dirs.add("pkgs")
for path in dest.rglob("*"):
    if any(part in skip_dirs for part in path.parts):
        continue
    if not path.is_file():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    updated = text
    for token, value in replacements.items():
        updated = updated.replace(token, value)
    if updated != text:
        path.write_text(updated, encoding="utf-8")

if use_mlkit:
    pyproject = dest / "pyproject.toml"
    text = pyproject.read_text(encoding="utf-8")
    old = '    "omegaconf",\n]'
    new = '    "omegaconf",\n    "mlkit",\n]'
    if old not in text:
        raise SystemExit("Error: could not add mlkit dependency to pyproject.toml")
    text = text.replace(old, new, 1)
    if "[tool.uv.sources]" not in text:
        text = text.rstrip() + "\n\n[tool.uv.sources]\nmlkit = { path = \"pkgs/my_pkg_py\", editable = true }\n"
    pyproject.write_text(text, encoding="utf-8")

    package = os.environ["PACKAGE_NAME"]
    extra = f"""

## mlkit training

This project uses the `mlkit` training pipeline from `pkgs/my_pkg_py` (uv editable). That clone is gitignored.

```bash
uv run python -m {package}.cli
bash shell_script/mc-run-python.sh {package}.cli
```

To depend on GitHub instead of the local clone, replace the `mlkit` path source in `pyproject.toml` with `git+https://github.com/zeroDtree/my_pkg_py`.
"""
    readme = dest / "README.md"
    readme.write_text(readme.read_text(encoding="utf-8") + extra, encoding="utf-8")
PY

APPLY_SH="$TEMPLATE_ROOT/ai-lorebook/apply.sh"
if [[ ! -f "$APPLY_SH" ]]; then
	echo "Error: ai-lorebook apply script is missing: $APPLY_SH" >&2
	exit 1
fi
bash "$APPLY_SH" -d "$DEST" -f

chmod +x "$DEST/shell_script/"*.sh 2>/dev/null || true
chmod +x "$DEST/shell_script/hpc/"*.sh 2>/dev/null || true
chmod +x "$DEST/shell_script/file_sync/"*.sh 2>/dev/null || true

if [[ "$NO_GIT" -eq 0 ]]; then
	git -C "$DEST" init -b main >/dev/null
fi

cat <<EOF
Created project at $DEST

Next:
  cd $DEST
  uv sync
  uv run ruff check
  uv run ty check
  uv run pytest
  uv run python -m $PACKAGE.cli --help
EOF
