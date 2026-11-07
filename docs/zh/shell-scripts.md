# Shell 脚本

在项目根目录用 `bash shell_script/...` 运行。每个启动脚本随后通过 `BASH_SOURCE` 切回仓库。帮助是英文，分成摘要块（`@help-begin`）和参数块（`@help-options-begin`）。

```bash
bash shell_script/run-python.sh --help
```

## 环境变量

| 变量 | 默认 | 用途 |
| --- | --- | --- |
| `MC_ENABLE_PROXY` | 关闭 | 在启动脚本之前设为 `1`。`prepare.sh` 会把 `http_proxy` 和 `https_proxy` 指到代理。 |
| `MC_PROXY_HOST` | `127.0.0.1` | 启用代理时的主机。 |
| `MC_PROXY_PORT` | `17890` | 启用代理时的端口。 |
| `MC_SKIP_UV_SYNC` | 关闭 | 设为 `1` 则跳过 `uv sync`。已经设置了 `SLURM_JOB_ID` 时，默认变成 `1`。 |
| `CUDA_VISIBLE_DEVICES` | 未设置 | `mc-run-python.sh` 的 GPU 编号。脚本数这些编号，或者数 `nvidia-smi -L` 的行数，并且至少要有一块。 |
| `SYNC_REMOTE` | r2l 必填 | 远程仓库根，例如 `user@host:/path/to/my-exp`。 |

仓库不会自己启动 Clash 或其他代理。先自己启动那个进程，再导出 `MC_ENABLE_PROXY=1`。

## CPU 和 GPU

CPU，或者任何不该经过 Accelerate 的运行：

```bash
bash shell_script/run-python.sh my_exp.cli
```

仅 GPU 的训练或评估。看不见 GPU 时会失败，并提示 CPU 改用 `run-python.sh`。

```bash
export MC_ENABLE_PROXY=1
bash shell_script/mc-run-python.sh my_exp.cli
```

`mc-run-python.sh` 用 `configs/accelerate/acc_cfg_base.yaml` 启动 `accelerate.commands.launch`，`--num_processes` 等于可见 GPU 的数量。它把命令记到 `artifacts/command_logs/`。退出码为 0 时调用 `email.sh`；邮件失败时进程仍以 0 退出。其他退出码不发邮件。

两个启动脚本都会调用 `uv sync`，除非 `MC_SKIP_UV_SYNC=1`，或者进程已经在 Slurm 作业里。

## 邮件

先复制示例，再填写 SMTP。`env_email.sh` 被 gitignore。不要提交密码。

```bash
cp shell_script/env_email.sh.example shell_script/env_email.sh
```

示例导出 `FROM_EMAIL`、`FROM_SMTP_HOST`、`FROM_SMTP_PORT`（默认 `994`）、`FROM_SMTP_PASSWORD` 和 `TO_EMAIL`。

```bash
bash shell_script/email.sh 0
bash shell_script/email.sh 0 -- my_exp.cli key=value
```

## 文件同步

`shell_script/file_sync/r2l.sh` 从远程检出把路径拉回本仓库，相对路径保持不变。把这些路径写在 `shell_script/file_sync/targets.txt`，一行一个相对路径。空行和 `#` 注释会被忽略。绝对路径和含有 `..` 的路径会被拒绝。

默认是 `rsync --dry-run`。真正复制要加 `--run` 或 `-y`。远程没有的本地文件会保留，因为 rsync 没有 `--delete`。

```bash
export SYNC_REMOTE=user@host:/path/to/my-exp
bash shell_script/file_sync/r2l.sh
bash shell_script/file_sync/r2l.sh --run
```

## Slurm

模板只带了 `shell_script/hpc/env.sh`，没有示例批处理脚本。在你自己添加的批处理脚本里 source `env.sh`，并且从仓库根目录提交作业。

`env.sh` 用 `SLURM_SUBMIT_DIR` 设置 `PROJECT_ROOT`，不用 `BASH_SOURCE`。Slurm 经常从 spool 目录运行批处理文件的副本，用脚本路径找仓库会找错。`SLURM_SUBMIT_DIR` 没设置时，这个辅助脚本会报错返回。

`CUDA_HOME` 默认是 `$HOME/software/cuda/cuda-12.4`。

计算节点常常没有网络，也没有代理。`sbatch` 之前在登录节点运行 `uv sync`。作业里面 `MC_SKIP_UV_SYNC` 的默认值已经是 `1`。
