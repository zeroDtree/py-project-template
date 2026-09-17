from __future__ import annotations

from pathlib import Path


def find_project_root(start: Path | None = None) -> Path:
    """Locate the repository root using its explicit marker file."""
    current = (start or Path(__file__)).resolve()
    if current.is_file():
        current = current.parent
    for candidate in (current, *current.parents):
        if (candidate / ".project-root").is_file():
            return candidate
    raise RuntimeError("Could not locate the project root marker '.project-root'")


PROJECT_ROOT = find_project_root()
CONFIG_ROOT = PROJECT_ROOT / "configs"
HYDRA_CONFIG_ROOT = CONFIG_ROOT / "hydra"
ARTIFACT_ROOT = PROJECT_ROOT / "artifacts"


def project_path(path: str | Path) -> Path:
    """Resolve a project-relative path without depending on the process CWD."""
    candidate = Path(path)
    return candidate if candidate.is_absolute() else PROJECT_ROOT / candidate
