from __future__ import annotations

import hydra
from omegaconf import DictConfig, OmegaConf

from __PACKAGE_NAME__.paths import HYDRA_CONFIG_ROOT


@hydra.main(version_base="1.3", config_path=str(HYDRA_CONFIG_ROOT), config_name="default.yaml")
def main(cfg: DictConfig) -> None:
    print(OmegaConf.to_yaml(cfg))


if __name__ == "__main__":
    main()
