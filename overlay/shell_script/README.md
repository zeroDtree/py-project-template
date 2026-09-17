# Shell scripts

Invoke as `bash shell_script/...` from the **project root**. Scripts then `cd` to the repo via `BASH_SOURCE`.

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `MC_ENABLE_PROXY` | off | Set to `1` **before** the runner (it sources `prepare.sh`) to enable HTTP proxy. |
| `MC_PROXY_HOST` | `127.0.0.1` | Proxy host when proxy is enabled. |
| `MC_PROXY_PORT` | `17890` | Proxy port when proxy is enabled. |
| `MC_SKIP_UV_SYNC` | off | Set to `1` to skip `uv sync` in `run-python.sh` / `mc-run-python.sh`. Under Slurm (`SLURM_JOB_ID` set), defaults to `1`. |
| `CUDA_VISIBLE_DEVICES` | unset | Comma-separated GPU ids; `mc-run-python.sh` uses this (or `nvidia-smi -L`) for `--num_processes`. |
| `SYNC_REMOTE` | (required for r2l) | Remote repo root for `file_sync/r2l.sh`, e.g. `user@host:/path/to/__PROJECT_NAME__`. |

## Run Python

CPU / no Accelerate:

```bash
bash shell_script/run-python.sh __PACKAGE_NAME__.cli
```

GPU training / eval with Accelerate. Logs the command under `artifacts/command_logs/` and emails on success (exit 0 only):

```bash
export MC_ENABLE_PROXY=1
bash shell_script/mc-run-python.sh __PACKAGE_NAME__.cli
```

Manage Clash or another local proxy separately; this repo does not start it automatically.

## Email

Copy `env_email.sh.example` to `env_email.sh` (gitignored) and fill in SMTP settings. `mc-run-python.sh` calls `email.sh` only when the run exits 0.

```bash
cp shell_script/env_email.sh.example shell_script/env_email.sh
bash shell_script/email.sh 0
```

## File sync

Pull files or directories from a remote checkout into this repo at the same relative path. Paths are listed in `file_sync/targets.txt` (one relative path per line; blank lines and `#` comments are ignored). Absolute paths and `..` are refused. Default is `rsync --dry-run`; pass `--run` or `-y` to copy. Local files missing on the remote are not deleted (`rsync` is not passed `--delete`).

```bash
export SYNC_REMOTE=user@host:/path/to/__PROJECT_NAME__
# edit shell_script/file_sync/targets.txt
bash shell_script/file_sync/r2l.sh          # dry-run
bash shell_script/file_sync/r2l.sh --run    # actually sync
```

## HPC / Slurm

This overlay ships `hpc/env.sh` only (no sample `.slurm` files). Source it from batch scripts you add. Submit those jobs from the **repo root**: `env.sh` sets `PROJECT_ROOT` from `SLURM_SUBMIT_DIR`, not `BASH_SOURCE`. Default `CUDA_HOME` is `$HOME/software/cuda/cuda-12.4`.

Sync the venv on the **login node** before submitting (compute nodes often have no network/proxy). Under Slurm, `MC_SKIP_UV_SYNC` defaults to `1`.
