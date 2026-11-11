# Shell scripts

Run scripts from the project root as `bash shell_script/...`. Each runner then `cd`s to the repo via `BASH_SOURCE`. Help is English and is split into a summary block (`@help-begin`) and a flag block (`@help-options-begin`).

```bash
bash shell_script/run-python.sh --help
```

## Post-init check

After init or clone, from the project root:

```bash
bash shell_script/init-check.sh
```

This syncs the `dev` group, runs `python -m my_exp.cli --help`, pytest, ruff, and ty, then installs the nbstripout git filter. Outside a git work tree the filter install is skipped. Set `MC_ENABLE_PROXY=1` before the script to enable the HTTP proxy for `uv sync`.

## Environment variables

| Variable | Default | Used by |
| --- | --- | --- |
| `MC_ENABLE_PROXY` | off | Set to `1` before a runner. `prepare.sh` then points `http_proxy` and `https_proxy` at the proxy. |
| `MC_PROXY_HOST` | `127.0.0.1` | Proxy host when the proxy is enabled. |
| `MC_PROXY_PORT` | `17890` | Proxy port when the proxy is enabled. |
| `MC_SKIP_UV_SYNC` | off | Set to `1` to skip `uv sync`. When `SLURM_JOB_ID` is set, the default becomes `1`. |
| `CUDA_VISIBLE_DEVICES` | unset | GPU ids for `mc-run-python.sh`. The script counts these, or the lines of `nvidia-smi -L`, and requires at least one. |
| `SYNC_REMOTE` | required for r2l | Remote repo root, for example `user@host:/path/to/my-exp`. |

Start Clash, or whatever proxy you use, yourself. Then `export MC_ENABLE_PROXY=1`.

## CPU and GPU

CPU, or a run that stays off Accelerate:

```bash
bash shell_script/run-python.sh my_exp.cli
```

GPU training or eval. With no visible GPU the script exits and names `run-python.sh` for CPU.

```bash
export MC_ENABLE_PROXY=1
bash shell_script/mc-run-python.sh my_exp.cli
```

`mc-run-python.sh` launches `accelerate.commands.launch` with `configs/accelerate/acc_cfg_base.yaml` and `--num_processes` equal to the visible GPU count. It records the command under `artifacts/command_logs/`. On exit code 0 it calls `email.sh` and still exits 0 if that mail fails. Other exit codes skip mail.

Both runners call `uv sync` unless `MC_SKIP_UV_SYNC=1` or the process is already inside a Slurm job.

## Email

Copy the example, then fill in the SMTP fields. `env_email.sh` is gitignored. Do not commit the password.

```bash
cp shell_script/env_email.sh.example shell_script/env_email.sh
```

The example exports `FROM_EMAIL`, `FROM_SMTP_HOST`, `FROM_SMTP_PORT` (default `994`), `FROM_SMTP_PASSWORD`, and `TO_EMAIL`.

```bash
bash shell_script/email.sh 0
bash shell_script/email.sh 0 -- my_exp.cli key=value
```

## File sync

`shell_script/file_sync/r2l.sh` pulls paths from a remote checkout into this repo at the same relative path. List those paths in `shell_script/file_sync/targets.txt`, one relative path per line. Blank lines and `#` comments are ignored. Absolute paths and `..` are refused.

The default is `rsync --dry-run`. Pass `--run` or `-y` to copy. Local files that are missing on the remote are kept, because rsync is invoked without `--delete`.

```bash
export SYNC_REMOTE=user@host:/path/to/my-exp
bash shell_script/file_sync/r2l.sh
bash shell_script/file_sync/r2l.sh --run
```

## Slurm

The overlay ships `shell_script/hpc/env.sh`. Write the batch script yourself, source `env.sh` from it, and submit that job from the repo root.

`env.sh` sets `PROJECT_ROOT` from `SLURM_SUBMIT_DIR`. Slurm often runs a copy of the batch file from a spool directory, so `BASH_SOURCE` points at the wrong place. If `SLURM_SUBMIT_DIR` is unset, the helper returns an error.

`CUDA_HOME` defaults to `$HOME/software/cuda/cuda-12.4`.

Compute nodes often have no network and no proxy. Run `uv sync` on the login node before `sbatch`. Inside the job, `MC_SKIP_UV_SYNC` already defaults to `1`.
