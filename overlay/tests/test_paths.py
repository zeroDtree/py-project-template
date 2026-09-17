from __future__ import annotations

from __PACKAGE_NAME__.paths import ARTIFACT_ROOT, HYDRA_CONFIG_ROOT, PROJECT_ROOT, project_path


def test_project_root_marker_exists() -> None:
    assert (PROJECT_ROOT / ".project-root").is_file()


def test_hydra_config_exists() -> None:
    assert (HYDRA_CONFIG_ROOT / "default.yaml").is_file()


def test_project_path_resolves_relative_paths() -> None:
    resolved = project_path("configs/hydra/default.yaml")
    assert resolved == PROJECT_ROOT / "configs" / "hydra" / "default.yaml"
    assert ARTIFACT_ROOT == PROJECT_ROOT / "artifacts"
