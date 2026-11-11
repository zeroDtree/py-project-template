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

    def test_unignore_mlkit_submodule_rewrites_pkgs_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / ".gitignore"
            path.write_text("# keep\n/pkgs/\n", encoding="utf-8")
            scaffold.unignore_mlkit_submodule(path)
            self.assertEqual(path.read_text(encoding="utf-8"), "# keep\n/pkgs/*\n!/pkgs/my_pkg_py\n")

    def test_unignore_mlkit_submodule_accepts_missing_trailing_newline(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / ".gitignore"
            path.write_text("# keep\n/pkgs/", encoding="utf-8")
            scaffold.unignore_mlkit_submodule(path)
            self.assertEqual(path.read_text(encoding="utf-8"), "# keep\n/pkgs/*\n!/pkgs/my_pkg_py\n")

    def test_unignore_mlkit_submodule_requires_pkgs_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / ".gitignore"
            path.write_text("# no pkgs rule\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                scaffold.unignore_mlkit_submodule(path)

    def test_finalize_track_mlkit_updates_gitignore_and_readme(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp)
            self._replaced_overlay(dest)
            (dest / ".gitignore").write_text("# keep\n/pkgs/\n", encoding="utf-8")
            (dest / "README.md").write_text("# __PROJECT_NAME__\n", encoding="utf-8")
            scaffold.finalize(
                dest,
                project_name="golden-exp",
                package_name="golden_exp",
                python_version="3.12",
                python_tag="py312",
                python_next="3.13",
                use_mlkit=True,
                track_mlkit=True,
            )
            gitignore = (dest / ".gitignore").read_text(encoding="utf-8")
            self.assertEqual(gitignore, "# keep\n/pkgs/*\n!/pkgs/my_pkg_py\n")
            readme = (dest / "README.md").read_text(encoding="utf-8")
            self.assertIn("# golden-exp\n", readme)
            self.assertIn("pkgs/my_pkg_py` submodule", readme)
            self.assertIn("--recurse-submodules", readme)
            self.assertNotIn("gitignored", readme)
            self.assertNotIn("git+https://", readme)
            data = tomllib.loads((dest / "pyproject.toml").read_text(encoding="utf-8"))
            self.assertEqual(data["tool"]["uv"]["sources"]["mlkit"]["path"], "pkgs/my_pkg_py")

    def test_finalize_mlkit_without_tracking_keeps_local_clone_note(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp)
            self._replaced_overlay(dest)
            (dest / ".gitignore").write_text("/pkgs/\n", encoding="utf-8")
            (dest / "README.md").write_text("# demo\n", encoding="utf-8")
            scaffold.finalize(
                dest,
                project_name="golden-exp",
                package_name="golden_exp",
                python_version="3.12",
                python_tag="py312",
                python_next="3.13",
                use_mlkit=True,
            )
            self.assertEqual((dest / ".gitignore").read_text(encoding="utf-8"), "/pkgs/\n")
            readme = (dest / "README.md").read_text(encoding="utf-8")
            self.assertIn("gitignored", readme)
            self.assertNotIn("--recurse-submodules", readme)

    def test_track_mlkit_requires_mlkit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(SystemExit):
                scaffold.finalize(
                    Path(tmp),
                    project_name="golden-exp",
                    package_name="golden_exp",
                    python_version="3.12",
                    python_tag="py312",
                    python_next="3.13",
                    use_mlkit=False,
                    track_mlkit=True,
                )


if __name__ == "__main__":
    unittest.main()
