#!/usr/bin/env bash

# @help-begin
# Pull files or directories listed in targets.txt from SYNC_REMOTE
# into this repo, preserving the same relative path from the project root.
#
# Usage:
#   bash shell_script/file_sync/r2l.sh
#   bash shell_script/file_sync/r2l.sh --run
#
# Env: SYNC_REMOTE — remote repo root. Example:
#   SYNC_REMOTE=user@host:/path/to/__PROJECT_NAME__ bash shell_script/file_sync/r2l.sh
#
# If no options are passed, the default behavior is equivalent to:
#   bash shell_script/file_sync/r2l.sh   # rsync --dry-run
# @help-end

# @help-options-begin
#   --run, -y               actually sync (omit for dry-run)
#   -h, --help              show help
# @help-options-end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGETS_FILE="${SCRIPT_DIR}/targets.txt"

usage() {
	awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0"
	printf '%s\n' '#' 'Options:' '#'
	awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0"
	exit 0
}

DO_RUN=0
while [[ $# -gt 0 ]]; do
	case "$1" in
	--run | -y)
		DO_RUN=1
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		echo "ERROR: unknown argument: $1" >&2
		awk '/^# @help-begin$/{f=1; next} /^# @help-end$/{f=0} f' "$0" >&2
		printf '%s\n' '#' 'Options:' '#' >&2
		awk '/^# @help-options-begin$/{f=1; next} /^# @help-options-end$/{f=0} f' "$0" >&2
		exit 1
		;;
	esac
done

if [[ -z "${SYNC_REMOTE:-}" ]]; then
	echo "ERROR: SYNC_REMOTE is unset." >&2
	echo "Example: export SYNC_REMOTE=user@host:/path/to/__PROJECT_NAME__" >&2
	exit 1
fi

if [[ ! -f "${TARGETS_FILE}" ]]; then
	echo "ERROR: missing targets file: ${TARGETS_FILE}" >&2
	exit 1
fi

REMOTE_ROOT="${SYNC_REMOTE%/}"
cd "${PROJECT_ROOT}" || exit 1

targets=()
while IFS= read -r raw || [[ -n "${raw}" ]]; do
	line="${raw%%#*}"
	line="${line#"${line%%[![:space:]]*}"}"
	line="${line%"${line##*[![:space:]]}"}"
	[[ -z "${line}" ]] && continue
	if [[ "${line}" == /* ]]; then
		echo "ERROR: refuse absolute path in targets.txt: ${line}" >&2
		exit 1
	fi
	if [[ "${line}" == *..* ]]; then
		echo "ERROR: refuse path with '..' in targets.txt: ${line}" >&2
		exit 1
	fi
	targets+=("${line%/}")
done <"${TARGETS_FILE}"

if [[ ${#targets[@]} -eq 0 ]]; then
	echo "ERROR: no paths in ${TARGETS_FILE} (empty lines and # comments are ignored)." >&2
	exit 1
fi

if [[ "${DO_RUN}" -eq 1 ]]; then
	mode="RUN"
	rsync_flags=(-avzP)
else
	mode="DRY-RUN"
	rsync_flags=(-avzP --dry-run)
fi

echo "===== file_sync r2l (${mode}) ====="
echo "PROJECT_ROOT : ${PROJECT_ROOT}"
echo "SYNC_REMOTE  : ${REMOTE_ROOT}"
echo "TARGETS      : ${TARGETS_FILE}"
echo "Paths:"
for relpath in "${targets[@]}"; do
	echo "  - ${relpath}"
done
echo

for relpath in "${targets[@]}"; do
	src="${REMOTE_ROOT}/${relpath}"
	dest="${PROJECT_ROOT}/${relpath}"
	if ! listing="$(rsync --list-only "${src}")"; then
		echo "ERROR: cannot list source: ${src}" >&2
		exit 1
	fi
	entry="$(printf '%s\n' "${listing}" | awk '/^[-dlbcps]/ { print; exit }')"
	if [[ -z "${entry}" ]]; then
		echo "ERROR: empty rsync listing for: ${src}" >&2
		exit 1
	fi

	if [[ "${entry}" == d* ]]; then
		src="${src}/"
		dest="${dest}/"
	elif [[ "${DO_RUN}" -eq 1 ]]; then
		mkdir -p "$(dirname "${dest}")"
	fi

	echo "---- rsync ${src} -> ${dest}"
	echo "     map: ${relpath} -> ${PROJECT_ROOT}/${relpath}"
	rsync "${rsync_flags[@]}" "${src}" "${dest}"
done

echo
echo "===== file_sync r2l (${mode}) done ====="
