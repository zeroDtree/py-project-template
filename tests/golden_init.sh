#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v uv >/dev/null 2>&1; then
	echo "Error: uv is required for the golden init checks" >&2
	echo "Install: https://docs.astral.sh/uv/getting-started/installation/" >&2
	exit 1
fi

uv_python() {
	uv run --project "$ROOT" python "$@"
}

uv_python -m unittest tests.test_scaffold

TMP="$(mktemp -d "${TMPDIR:-/tmp}/py-template-golden.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

TOKENS='__PROJECT_NAME__|__PACKAGE_NAME__|__PYTHON_VERSION__|__PYTHON_TAG__|__PYTHON_NEXT__'

assert_no_tokens() {
	local dest="$1"
	if [[ "${2:-}" == "skip-pkgs" ]]; then
		if grep -R -E --exclude-dir=.git --exclude-dir=.venv --exclude-dir=__pycache__ \
			--exclude-dir=pkgs "$TOKENS" "$dest"; then
			echo "Error: leftover template tokens in $dest" >&2
			exit 1
		fi
	else
		if grep -R -E --exclude-dir=.git --exclude-dir=.venv --exclude-dir=__pycache__ \
			"$TOKENS" "$dest"; then
			echo "Error: leftover template tokens in $dest" >&2
			exit 1
		fi
	fi
}

submodule_ok() {
	local path="$1"
	git -C "$ROOT/$path" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

echo "==> base init"
BASE="$TMP/golden-exp"
"$ROOT/init.sh" --dest "$BASE" --name golden-exp --no-git
assert_no_tokens "$BASE"
if [[ -e "$BASE/.cursor" || -e "$BASE/.claude" || -d "$BASE/.github/instructions" ]]; then
	echo "Error: lorebook files present without --lorebook" >&2
	exit 1
fi
(
	cd "$BASE"
	bash shell_script/init-check.sh
)

echo "==> dotted project name derives the import package"
DOTTED="$TMP/dotted"
"$ROOT/init.sh" --dest "$DOTTED" --name my.exp --no-git
[[ -d "$DOTTED/src/my_exp" ]]
uv_python - "$DOTTED/pyproject.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

data = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data["project"]["name"] == "my.exp", data["project"]["name"]
assert data["project"]["scripts"]["my.exp"] == "my_exp.cli:main", data["project"]["scripts"]
assert data["tool"]["hatch"]["build"]["targets"]["wheel"]["packages"] == ["src/my_exp"]
print("dotted name ok")
PY

echo "==> --package overrides the derived import name"
OVERRIDE="$TMP/override"
"$ROOT/init.sh" --dest "$OVERRIDE" --name acme-lab --package lab --no-git
[[ -d "$OVERRIDE/src/lab" ]]
uv_python - "$OVERRIDE/pyproject.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

data = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data["project"]["name"] == "acme-lab", data["project"]["name"]
assert data["project"]["scripts"]["acme-lab"] == "lab.cli:main", data["project"]["scripts"]
assert data["tool"]["hatch"]["build"]["targets"]["wheel"]["packages"] == ["src/lab"]
print("package override ok")
PY

echo "==> --mlkit pin and TOML"
if submodule_ok my_pkg_py; then
	MLKIT="$TMP/golden-mlkit"
	"$ROOT/init.sh" --dest "$MLKIT" --name golden-mlkit --mlkit --https --no-git \
		2>"$TMP/mlkit-nogit.err"
	grep -q "does not register" "$TMP/mlkit-nogit.err"
	grep -q '^/pkgs/$' "$MLKIT/.gitignore"
	if grep -q '!/pkgs/my_pkg_py' "$MLKIT/.gitignore"; then
		echo "Error: --no-git un-ignored pkgs/my_pkg_py" >&2
		exit 1
	fi
	grep -q "gitignored" "$MLKIT/README.md"
	assert_no_tokens "$MLKIT" skip-pkgs
	expected="$(git -C "$ROOT/my_pkg_py" rev-parse HEAD)"
	actual="$(git -C "$MLKIT/pkgs/my_pkg_py" rev-parse HEAD)"
	if [[ "$expected" != "$actual" ]]; then
		echo "Error: mlkit pin mismatch: expected $expected got $actual" >&2
		exit 1
	fi
	origin="$(git -C "$MLKIT/pkgs/my_pkg_py" remote get-url origin)"
	case "$origin" in
		https://*) ;;
		*)
			echo "Error: expected HTTPS origin, got $origin" >&2
			exit 1
			;;
	esac
	[[ -f "$MLKIT/src/golden_mlkit/train.py" ]]
	[[ -f "$MLKIT/configs/hydra/model/default.yaml" ]]
	[[ -f "$MLKIT/configs/hydra/dataset/default.yaml" ]]
	[[ -f "$MLKIT/configs/hydra/wandb/default.yaml" ]]
	uv_python - "$MLKIT/pyproject.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

data = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert "mlkit" in data["project"]["dependencies"], data["project"]["dependencies"]
source = data["tool"]["uv"]["sources"]["mlkit"]
assert source["path"] == "pkgs/my_pkg_py", source
assert source["editable"] is True, source
print("mlkit pyproject ok")
PY

	echo "==> --mlkit submodule pin"
	GITML="$TMP/golden-mlkit-git"
	"$ROOT/init.sh" --dest "$GITML" --name golden-mlkit-git --mlkit --https
	assert_no_tokens "$GITML" skip-pkgs
	expected="$(git -C "$ROOT/my_pkg_py" rev-parse HEAD)"
	actual="$(git -C "$GITML/pkgs/my_pkg_py" rev-parse HEAD)"
	if [[ "$expected" != "$actual" ]]; then
		echo "Error: mlkit submodule pin mismatch: expected $expected got $actual" >&2
		exit 1
	fi
	stage="$(git -C "$GITML" ls-files -s -- pkgs/my_pkg_py)"
	mode="${stage%% *}"
	rest="${stage#* }"
	sha="${rest%% *}"
	if [[ "$mode" != "160000" || "$sha" != "$expected" ]]; then
		echo "Error: expected gitlink 160000 $expected, got: $stage" >&2
		exit 1
	fi
	recorded="$(git -C "$GITML" config --file "$GITML/.gitmodules" --get submodule.my_pkg_py.url)"
	case "$recorded" in
		https://*) ;;
		*)
			echo "Error: expected HTTPS submodule URL, got $recorded" >&2
			exit 1
			;;
	esac
	path_entry="$(git -C "$GITML" config --file "$GITML/.gitmodules" --get submodule.my_pkg_py.path)"
	if [[ "$path_entry" != "pkgs/my_pkg_py" ]]; then
		echo "Error: unexpected submodule path: $path_entry" >&2
		exit 1
	fi
	origin="$(git -C "$GITML/pkgs/my_pkg_py" remote get-url origin)"
	if [[ "$origin" != "$recorded" ]]; then
		echo "Error: submodule origin $origin does not match .gitmodules $recorded" >&2
		exit 1
	fi
	if git -C "$GITML" check-ignore -q -- pkgs/my_pkg_py; then
		echo "Error: pkgs/my_pkg_py is ignored" >&2
		exit 1
	fi
	if [[ ! -f "$GITML/pkgs/my_pkg_py/.git" ]]; then
		echo "Error: pkgs/my_pkg_py/.git is not a gitfile" >&2
		exit 1
	fi
	grep -q '!/pkgs/my_pkg_py' "$GITML/.gitignore"
	grep -q -- '--recurse-submodules' "$GITML/README.md"
else
	if [[ "${CI:-}" == "true" ]]; then
		echo "Error: my_pkg_py submodule is required in CI" >&2
		exit 1
	fi
	echo "skip --mlkit (submodule missing)"
fi

echo "==> --lorebook"
if [[ -f "$ROOT/ai-lorebook/apply.sh" ]]; then
	LORE="$TMP/golden-lore"
	"$ROOT/init.sh" --dest "$LORE" --name golden-lore --lorebook --no-git
	assert_no_tokens "$LORE"
	[[ -d "$LORE/.cursor/rules" ]]
else
	if [[ "${CI:-}" == "true" ]]; then
		echo "Error: ai-lorebook submodule is required in CI" >&2
		exit 1
	fi
	echo "skip --lorebook (submodule missing)"
fi

echo "golden init ok"
