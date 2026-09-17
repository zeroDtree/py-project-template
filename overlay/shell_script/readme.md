# Shell scripts

Run all scripts in this folder from the **project root** directory.

## Environment variables

| Variable          | Default     | Description |
| ----------------- | ----------- | ----------- |
| `MC_ENABLE_PROXY` | off         | Set to `1` before sourcing `prepare.sh` to enable HTTP proxy (`127.0.0.1:17890` by default). |
| `MC_PROXY_HOST`   | `127.0.0.1` | Proxy host when proxy is enabled. |
| `MC_PROXY_PORT`   | `17890`     | Proxy port when proxy is enabled. |
| `MC_SKIP_UV_SYNC` | off         | Set to `1` in `run-python.sh` to skip `uv sync`. Under Slurm (`SLURM_JOB_ID` set), defaults to `1`. |

## Run Python

```bash
bash shell_script/run-python.sh __PACKAGE_NAME__.cli
```

## HPC / Slurm

Submit from the **repo root**. Shared CUDA / `PROJECT_ROOT` bootstrap lives in `hpc/env.sh` (sourced by batch scripts; uses `SLURM_SUBMIT_DIR`, not `BASH_SOURCE`).

Sync the venv on the **login node** before submitting jobs (compute nodes often have no network/proxy). Under Slurm, `MC_SKIP_UV_SYNC` defaults to `1`.
