from __future__ import annotations

import sys
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import scaffold  # noqa: E402


OVERLAY_PYPROJECT = ROOT / "overlay" / "pyproject.toml"


class RewriteGitUrlTests(unittest.TestCase):
    def test_scp_ssh_to_https(self) -> None:
        self.assertEqual(
            scaffold.rewrite_git_url("git@github.com:zeroDtree/my_pkg_py.git", to_https=True),
            "https://github.com/zeroDtree/my_pkg_py.git",
        )

    def test_ssh_scheme_to_https(self) -> None:
        self.assertEqual(
            scaffold.rewrite_git_url("ssh://git@github.com/zeroDtree/my_pkg_py.git", to_https=True),
            "https://github.com/zeroDtree/my_pkg_py.git",
        )

    def test_https_unchanged(self) -> None:
        url = "https://github.com/zeroDtree/my_pkg_py.git"
        self.assertEqual(scaffold.rewrite_git_url(url, to_https=True), url)

    def test_to_https_false_leaves_ssh(self) -> None:
        url = "git@github.com:zeroDtree/my_pkg_py.git"
        self.assertEqual(scaffold.rewrite_git_url(url, to_https=False), url)

    def test_want_https_from_origin(self) -> None:
        self.assertTrue(scaffold.want_https(force=False, origin="https://github.com/zeroDtree/py-project-template.git"))
        self.assertFalse(scaffold.want_https(force=False, origin="git@github.com:zeroDtree/py-project-template.git"))
        self.assertTrue(scaffold.want_https(force=True, origin="git@github.com:zeroDtree/py-project-template.git"))
        self.assertFalse(scaffold.want_https(force=False, origin=None))


class TokenReplaceTests(unittest.TestCase):
    def test_replaces_and_skips_pkgs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp)
            (dest / "src").mkdir()
            (dest / "src" / "pkg.py").write_text("import __PACKAGE_NAME__\n", encoding="utf-8")
            pkgs = dest / "pkgs" / "my_pkg_py"
            pkgs.mkdir(parents=True)
            (pkgs / "keep.py").write_text("__PACKAGE_NAME__\n", encoding="utf-8")
            scaffold.replace_tokens(
                dest,
                {"__PACKAGE_NAME__": "golden_exp"},
                skip_pkgs=True,
            )
            self.assertEqual((dest / "src" / "pkg.py").read_text(encoding="utf-8"), "import golden_exp\n")
            self.assertEqual((pkgs / "keep.py").read_text(encoding="utf-8"), "__PACKAGE_NAME__\n")


class PyprojectTests(unittest.TestCase):
    def _replaced_overlay(self, dest: Path) -> Path:
        text = OVERLAY_PYPROJECT.read_text(encoding="utf-8")
        replacements = {
            "__PROJECT_NAME__": "golden-exp",
            "__PACKAGE_NAME__": "golden_exp",
            "__PYTHON_VERSION__": "3.12",
            "__PYTHON_TAG__": "py312",
            "__PYTHON_NEXT__": "3.13",
        }
        for token, value in replacements.items():
            text = text.replace(token, value)
        path = dest / "pyproject.toml"
        path.write_text(text, encoding="utf-8")
        return path

    def test_dump_roundtrip_overlay_pyproject(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._replaced_overlay(Path(tmp))
            original = tomllib.loads(path.read_text(encoding="utf-8"))
            dumped = scaffold.dump_toml(original)
            self.assertEqual(tomllib.loads(dumped), original)

    def test_add_mlkit_is_semantic_and_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._replaced_overlay(Path(tmp))
            scaffold.add_mlkit_pyproject(path)
            data = tomllib.loads(path.read_text(encoding="utf-8"))
            self.assertIn("mlkit", data["project"]["dependencies"])
            self.assertEqual(data["project"]["dependencies"].count("mlkit"), 1)
            source = data["tool"]["uv"]["sources"]["mlkit"]
            self.assertEqual(source["path"], "pkgs/my_pkg_py")
            self.assertTrue(source["editable"])
            self.assertEqual(data["project"]["name"], "golden-exp")
            self.assertEqual(data["project"]["scripts"]["golden-exp"], "golden_exp.cli:main")
            self.assertEqual(data["tool"]["uv"]["package"], True)

            scaffold.add_mlkit_pyproject(path)
            again = tomllib.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(again["project"]["dependencies"].count("mlkit"), 1)
            self.assertEqual(again["tool"]["uv"]["sources"]["mlkit"], source)


if __name__ == "__main__":
    unittest.main()
