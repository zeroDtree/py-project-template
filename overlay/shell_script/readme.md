# Shell scripts

Run all scripts in this folder from the **project root** directory.

## Environment variables

| Variable          | Default     | Description |
| ----------------- | ----------- | ----------- |
| `MC_ENABLE_PROXY` | off         | Set to `1` before sourcing `prepare.sh` to enable HTTP proxy (`127.0.0.1:17890` by default). |
| `MC_PROXY_HOST`   | `127.0.0.1` | Proxy host when proxy is enabled. |
| `MC_PROXY_PORT`   | `17890`     | Proxy port when proxy is enabled. |
| `MC_SKIP_UV_SYNC` | off         | Set to `1` in `run-python.sh` / `mc-run-python.sh` to skip `uv sync`. Under Slurm (`SLURM_JOB_ID` set), defaults to `1`. |
| `SYNC_REMOTE`     | (required)  | Remote repo root for `file_sync/r2l.sh`, e.g. `user@host:/path/to/__PROJECT_NAME__`. |

## Run Python

CPU / no Accelerate:

```bash
bash shell_script/run-python.sh __PACKAGE_NAME__.cli
```

GPU training / eval with Accelerate. Logs the command under `artifacts/command_logs/` and emails on success:

```bash
export MC_ENABLE_PROXY=1
bash shell_script/mc-run-python.sh __PACKAGE_NAME__.cli
```

Manage Clash or another local proxy separately; this repo does not start it automatically.

## Email

Copy `env_email.sh.example` to `env_email.sh` (gitignored) and fill in SMTP settings. `mc-run-python.sh` calls `email.sh` after a successful run.

```bash
cp shell_script/env_email.sh.example shell_script/env_email.sh
bash shell_script/email.sh 0
```

## File sync

Pull untracked files or directories from a remote checkout into this repo. Paths are listed in `file_sync/targets.txt` (one relative path per line; blank lines and `#` comments are ignored). Default is `rsync --dry-run`; pass `--run` to copy.

```bash
export SYNC_REMOTE=user@host:/path/to/__PROJECT_NAME__
# edit shell_script/file_sync/targets.txt
bash shell_script/file_sync/r2l.sh          # dry-run
bash shell_script/file_sync/r2l.sh --run    # actually sync
```

Does not delete local files that are missing on the remote.

## HPC / Slurm

Submit from the **repo root**. Shared CUDA / `PROJECT_ROOT` bootstrap lives in `hpc/env.sh` (sourced by batch scripts; uses `SLURM_SUBMIT_DIR`, not `BASH_SOURCE`).

Sync the venv on the **login node** before submitting jobs (compute nodes often have no network/proxy). Under Slurm, `MC_SKIP_UV_SYNC` defaults to `1`.
