#!/usr/bin/env python3
"""Stdlib helpers for init.sh: token replace, git URL rewrite, pyproject TOML edit."""

from __future__ import annotations

import argparse
import re
import tomllib
from pathlib import Path
from typing import Any

MLKIT_PATH = "pkgs/my_pkg_py"
SKIP_DIRS = {".git", ".venv", "__pycache__"}
_BARE_KEY = re.compile(r"^[A-Za-z0-9_-]+$")
_SSH_SCP = re.compile(r"^git@([^:]+):(.+)$")
_SSH_URL = re.compile(r"^ssh://git@([^/]+)/(.+)$")

MLKIT_README = """

## mlkit training

This project uses the `mlkit` training pipeline from `pkgs/my_pkg_py` (uv editable), cloned at this template's submodule commit. That clone is gitignored.

```bash
uv run python -m {package}.cli
bash shell_script/mc-run-python.sh {package}.cli
```

To depend on GitHub instead of the local clone, replace the `mlkit` path source in `pyproject.toml` with `git+https://github.com/zeroDtree/my_pkg_py`.
"""


def rewrite_git_url(url: str, *, to_https: bool) -> str:
    """Convert SSH Git URLs to HTTPS. HTTPS URLs are left unchanged."""
    if not to_https:
        return url
    if url.startswith(("https://", "http://")):
        return url
    matched = _SSH_SCP.match(url)
    if matched:
        return f"https://{matched.group(1)}/{matched.group(2)}"
    matched = _SSH_URL.match(url)
    if matched:
        return f"https://{matched.group(1)}/{matched.group(2)}"
    return url


def want_https(*, force: bool, origin: str | None) -> bool:
    if force:
        return True
    return bool(origin and origin.startswith(("https://", "http://")))


def replace_tokens(dest: Path, replacements: dict[str, str], *, skip_pkgs: bool = False) -> None:
    skip = set(SKIP_DIRS)
    if skip_pkgs:
        skip.add("pkgs")
    for path in dest.rglob("*"):
        if any(part in skip for part in path.parts):
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


def _format_key(key: str) -> str:
    if _BARE_KEY.fullmatch(key):
        return key
    return _format_string(key)


def _format_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")
    return f'"{escaped}"'


def _all_scalars(table: dict[str, Any]) -> bool:
    return all(not isinstance(value, (dict, list)) for value in table.values())


def _is_inline_table_map(table: dict[str, Any]) -> bool:
    return bool(table) and all(isinstance(value, dict) and _all_scalars(value) for value in table.values())


def _format_inline_table(table: dict[str, Any]) -> str:
    inner = ", ".join(f"{_format_key(key)} = {_format_value(value)}" for key, value in table.items())
    return f"{{ {inner} }}"


def _format_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, str):
        return _format_string(value)
    if isinstance(value, list):
        if not value:
            return "[]"
        if all(isinstance(item, dict) for item in value):
            return "[ " + ", ".join(_format_inline_table(item) for item in value) + " ]"
        if all(isinstance(item, str) for item in value) and len(value) > 1:
            lines = ",\n".join(f"    {_format_string(item)}" for item in value)
            return f"[\n{lines},\n]"
        return "[ " + ", ".join(_format_value(item) for item in value) + " ]"
    if isinstance(value, dict):
        return _format_inline_table(value)
    raise TypeError(f"unsupported TOML value type: {type(value)!r}")


def dump_toml(data: dict[str, Any]) -> str:
    """Serialize a tomllib-loaded dict. Good enough for this overlay pyproject."""
    parts: list[str] = []

    def emit_table(header: str, table: dict[str, Any]) -> None:
        if _is_inline_table_map(table):
            if header:
                parts.append(f"[{header}]")
            for key, value in table.items():
                parts.append(f"{_format_key(key)} = {_format_inline_table(value)}")
            parts.append("")
            return

        scalars = [(key, value) for key, value in table.items() if not isinstance(value, dict)]
        nested = [(key, value) for key, value in table.items() if isinstance(value, dict)]
        if scalars or not nested:
            if header:
                parts.append(f"[{header}]")
            for key, value in scalars:
                parts.append(f"{_format_key(key)} = {_format_value(value)}")
            parts.append("")
        for key, value in nested:
            child = f"{header}.{key}" if header else key
            emit_table(child, value)

    emit_table("", data)
    return "\n".join(parts).rstrip() + "\n"


def add_mlkit_pyproject(path: Path) -> None:
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    deps = data.setdefault("project", {}).setdefault("dependencies", [])
    if "mlkit" not in deps:
        deps.append("mlkit")
    sources = data.setdefault("tool", {}).setdefault("uv", {}).setdefault("sources", {})
    sources["mlkit"] = {"path": MLKIT_PATH, "editable": True}
    path.write_text(dump_toml(data), encoding="utf-8")


def append_mlkit_readme(path: Path, package_name: str) -> None:
    extra = MLKIT_README.format(package=package_name)
    path.write_text(path.read_text(encoding="utf-8") + extra, encoding="utf-8")


def finalize(
    dest: Path,
    *,
    project_name: str,
    package_name: str,
    python_version: str,
    python_tag: str,
    python_next: str,
    use_mlkit: bool,
) -> None:
    replacements = {
        "__PROJECT_NAME__": project_name,
        "__PACKAGE_NAME__": package_name,
        "__PYTHON_VERSION__": python_version,
        "__PYTHON_TAG__": python_tag,
        "__PYTHON_NEXT__": python_next,
    }
    replace_tokens(dest, replacements, skip_pkgs=use_mlkit)
    if use_mlkit:
        add_mlkit_pyproject(dest / "pyproject.toml")
        append_mlkit_readme(dest / "README.md", package_name)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="scaffold.py")
    sub = parser.add_subparsers(dest="cmd", required=True)

    finalize_cmd = sub.add_parser("finalize", help="replace tokens and optionally add mlkit")
    finalize_cmd.add_argument("--dest", required=True)
    finalize_cmd.add_argument("--project-name", required=True)
    finalize_cmd.add_argument("--package-name", required=True)
    finalize_cmd.add_argument("--python-version", required=True)
    finalize_cmd.add_argument("--python-tag", required=True)
    finalize_cmd.add_argument("--python-next", required=True)
    finalize_cmd.add_argument("--mlkit", action="store_true")

    rewrite_cmd = sub.add_parser("rewrite-url", help="optionally rewrite a git URL to HTTPS")
    rewrite_cmd.add_argument("url")
    rewrite_cmd.add_argument("--https", action="store_true")

    args = parser.parse_args(argv)
    if args.cmd == "rewrite-url":
        print(rewrite_git_url(args.url, to_https=args.https))
        return 0
    if args.cmd == "finalize":
        finalize(
            Path(args.dest),
            project_name=args.project_name,
            package_name=args.package_name,
            python_version=args.python_version,
            python_tag=args.python_tag,
            python_next=args.python_next,
            use_mlkit=args.mlkit,
        )
        return 0
    raise AssertionError(args.cmd)


if __name__ == "__main__":
    raise SystemExit(main())
