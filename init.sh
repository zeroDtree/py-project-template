#!/usr/bin/env bash

# @help-begin
# Initialize a new Python project from this template.
#
# Usage:
#   ./init.sh --dest PATH [--name NAME] [--package PKG] [--python VERSION]
#              [--mlkit] [--lorebook] [--https] [--no-git]
#
# This script only creates new projects. The destination must not exist,
# or must be an empty directory. uv is required; it provides Python 3.12.
#
# --mlkit copies the pinned my_pkg_py submodule into pkgs/ (gitignored)
# and scaffolds the mlkit training pipeline. Requires:
#   git submodule update --init my_pkg_py
#
# --lorebook copies Cursor / Copilot / Claude rules via ai-lorebook/apply.sh.
# Off by default. Requires:
#   git submodule update --init ai-lorebook
#
# --https rewrites the pkgs/my_pkg_py origin to HTTPS. Also used automatically
# when this template's origin remote is already HTTPS.
#
# After init, install dependencies from the new project root:
#   cd PATH && uv sync
# @help-end

# @help-options-begin
#   --dest PATH             destination directory for the new project (required)
#   --name NAME             project name (default: destination basename)
#   --package PKG           import package name (default: NAME with '-' -> '_')
#   --python VERSION        Python version (default: 3.12)
#   --mlkit                 clone pinned my_pkg_py into pkgs/ and scaffold mlkit
#   --lorebook              copy AI rules from ai-lorebook (off by default)
#   --https                 use HTTPS for the pkgs/my_pkg_py origin URL
#   --no-git                skip git init in the destination
#   -h, --help              show help
# @help-options-end

set -euo pipefail

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY="$TEMPLATE_ROOT/overlay"
OVERLAY_MLKIT="$TEMPLATE_ROOT/overlay_mlkit"
SCAFFOLD_PY="$TEMPLATE_ROOT/scaffold.py"
DEFAULT_MLKIT_URL="git@github.com:zeroDtree/my_pkg_py.git"

usage() {
	awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0"
	printf '%s\n' '#' 'Options:' '#'
	awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0"
	exit 0
}

require_uv() {
	if ! command -v uv >/dev/null 2>&1; then
		echo "Error: uv is required to run init.sh." >&2
		echo "Install: https://docs.astral.sh/uv/getting-started/installation/" >&2
		exit 1
	fi
}

uv_python() {
	uv run --project "$TEMPLATE_ROOT" python "$@"
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
USE_LOREBOOK=0
FORCE_HTTPS=0

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
		--lorebook)
			USE_LOREBOOK=1
			shift
			;;
		--https)
			FORCE_HTTPS=1
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
if [[ ! -f "$SCAFFOLD_PY" ]]; then
	echo "Error: scaffold helper is missing: $SCAFFOLD_PY" >&2
	exit 1
fi

require_uv

mlkit_url() {
	local url
	url="$(git -C "$TEMPLATE_ROOT" config --file "$TEMPLATE_ROOT/.gitmodules" --get submodule.my_pkg_py.url 2>/dev/null || true)"
	printf '%s\n' "${url:-$DEFAULT_MLKIT_URL}"
}

clone_mlkit() {
	local src="$TEMPLATE_ROOT/my_pkg_py"
	local dest_pkg="$DEST/pkgs/my_pkg_py"
	local pin actual url origin rewritten to_https

	if [[ ! -d "$OVERLAY_MLKIT" ]]; then
		echo "Error: overlay_mlkit directory is missing: $OVERLAY_MLKIT" >&2
		exit 1
	fi
	if ! git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "Error: submodule my_pkg_py is missing or uninitialized." >&2
		echo "Run: git submodule update --init my_pkg_py" >&2
		exit 1
	fi

	pin="$(git -C "$src" rev-parse HEAD)"
	mkdir -p "$DEST/pkgs"
	git clone "$src" "$dest_pkg"
	actual="$(git -C "$dest_pkg" rev-parse HEAD)"
	if [[ "$actual" != "$pin" ]]; then
		echo "Error: cloned my_pkg_py HEAD $actual does not match pin $pin" >&2
		exit 1
	fi

	url="$(mlkit_url)"
	origin="$(git -C "$TEMPLATE_ROOT" remote get-url origin 2>/dev/null || true)"
	to_https=0
	if [[ "$FORCE_HTTPS" -eq 1 ]]; then
		to_https=1
	elif [[ "$origin" == https://* || "$origin" == http://* ]]; then
		to_https=1
	fi
	if [[ "$to_https" -eq 1 ]]; then
		rewritten="$(uv_python "$SCAFFOLD_PY" rewrite-url "$url" --https)"
	else
		rewritten="$url"
	fi
	git -C "$dest_pkg" remote set-url origin "$rewritten"
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

finalize_args=(
	finalize
	--dest "$DEST"
	--project-name "$NAME"
	--package-name "$PACKAGE"
	--python-version "$PYTHON_VERSION"
	--python-tag "$PYTHON_TAG"
	--python-next "$PYTHON_NEXT"
)
if [[ "$USE_MLKIT" -eq 1 ]]; then
	finalize_args+=(--mlkit)
fi
uv_python "$SCAFFOLD_PY" "${finalize_args[@]}"

if [[ "$USE_LOREBOOK" -eq 1 ]]; then
	APPLY_SH="$TEMPLATE_ROOT/ai-lorebook/apply.sh"
	if [[ ! -f "$APPLY_SH" ]]; then
		echo "Error: ai-lorebook apply script is missing: $APPLY_SH" >&2
		echo "Run: git submodule update --init ai-lorebook" >&2
		exit 1
	fi
	bash "$APPLY_SH" -d "$DEST" -f
fi

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
