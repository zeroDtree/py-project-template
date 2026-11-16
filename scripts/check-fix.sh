#!/usr/bin/env bash

# @help-begin
# Auto-fix lint style and run the quality checks from the repository root.
#
# Usage:
#   bash scripts/check-fix.sh [--check]
#
# Default (fix mode):
#   ruff check --fix, ruff format, ruff check, ruff format --check,
#   ty check, pytest
#
# --check (verify only, no writes):
#   ruff check, ruff format --check, ty check, pytest
#
# uv run syncs the project environment first, so ruff, ty, and pytest are
# installed on demand.
# @help-end

# @help-options-begin
#   --check                 verify only; do not rewrite files
#   -h, --help              show help
# @help-options-end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
	awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0"
	printf '%s\n' '#' 'Options:' '#'
	awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0"
	exit 0
}

MODE="fix"
case "${1:-}" in
	-h|--help) usage ;;
	--check) MODE="check" ;;
	"") ;;
	*)
		echo "Error: unknown argument: $1" >&2
		exit 1
		;;
esac

cd "$PROJECT_ROOT" || exit 1

if [[ "$MODE" == "fix" ]]; then
	echo "==> uv run ruff check --fix"
	uv run ruff check --fix
	echo "==> uv run ruff format"
	uv run ruff format
fi

echo "==> uv run ruff check"
uv run ruff check
echo "==> uv run ruff format --check"
uv run ruff format --check
echo "==> uv run ty check"
uv run ty check
echo "==> uv run pytest"
uv run pytest
