#!/usr/bin/env bash

# @help-begin
# Initialize a new Python project from this template.
#
# Usage:
#   ./init.sh --dest PATH [--name NAME] [--package PKG] [--python VERSION]
#
# This script only creates new projects. The destination must not exist,
# or must be an empty directory.
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
#   --no-git                skip git init in the destination
#   -h, --help              show help
# @help-options-end

set -euo pipefail

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY="$TEMPLATE_ROOT/overlay"

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

cp -a "$OVERLAY/." "$DEST/"

PACKAGE_SRC="$DEST/src/__PACKAGE_NAME__"
if [[ -d "$PACKAGE_SRC" ]]; then
	mv "$PACKAGE_SRC" "$DEST/src/$PACKAGE"
fi

export DEST PROJECT_NAME="$NAME" PACKAGE_NAME="$PACKAGE" PYTHON_VERSION PYTHON_TAG PYTHON_NEXT
python3 - <<'PY'
import os
from pathlib import Path

dest = Path(os.environ["DEST"])
replacements = {
    "__PROJECT_NAME__": os.environ["PROJECT_NAME"],
    "__PACKAGE_NAME__": os.environ["PACKAGE_NAME"],
    "__PYTHON_VERSION__": os.environ["PYTHON_VERSION"],
    "__PYTHON_TAG__": os.environ["PYTHON_TAG"],
    "__PYTHON_NEXT__": os.environ["PYTHON_NEXT"],
}
skip_dirs = {".git", ".venv", "__pycache__"}
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
