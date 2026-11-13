# Shell 脚本

在项目根目录用 `bash shell_script/...` 调用。启动脚本再用 `BASH_SOURCE` 回到仓库。帮助是英文，摘要在 `@help-begin`，参数在 `@help-options-begin`。

```bash
bash shell_script/run-python.sh --help
```

## 初始化检查

创建或克隆之后，在项目根目录：

```bash
bash shell_script/init-check.sh
```

脚本会 `uv sync`（安装 `dev` 组），然后跑 `python -m my_exp.cli --help`、pytest、ruff 和 ty，并安装 nbstripout 的 git 过滤器。不在 git 工作树里时跳过过滤器安装。运行前 `export MC_ENABLE_PROXY=1` 会给 `uv sync` 打开 HTTP 代理。

## 环境变量

| 变量 | 默认 | 用途 |
| --- | --- | --- |
| `MC_ENABLE_PROXY` | 关闭 | 在启动脚本之前设为 `1`。`prepare.sh` 会把 `http_proxy` 和 `https_proxy` 指到代理。 |
| `MC_PROXY_HOST` | `127.0.0.1` | 启用代理时的主机。 |
| `MC_PROXY_PORT` | `17890` | 启用代理时的端口。 |
| `MC_SKIP_UV_SYNC` | 关闭 | 设为 `1` 则跳过 `uv sync`。已经设置了 `SLURM_JOB_ID` 时，默认变成 `1`。 |
| `CUDA_VISIBLE_DEVICES` | 未设置 | `mc-run-python.sh` 的 GPU 编号。脚本数这些编号，或者数 `nvidia-smi -L` 的行数，并且至少要有一块。 |
| `SYNC_REMOTE` | r2l 必填 | 远程仓库根，例如 `user@host:/path/to/my-exp`。 |

Clash 或其他代理自己先开好，再 `export MC_ENABLE_PROXY=1`。

## CPU 和 GPU

CPU，以及不经过 Accelerate 的运行：

```bash
bash shell_script/run-python.sh my_exp.cli
```

GPU 上的训练或评估。看不到 GPU 时脚本退出，CPU 用 `run-python.sh`。

```bash
export MC_ENABLE_PROXY=1
bash shell_script/mc-run-python.sh my_exp.cli
```

`mc-run-python.sh` 用 `configs/accelerate/acc_cfg_base.yaml` 启动 `accelerate.commands.launch`，`--num_processes` 等于可见 GPU 数。命令记在 `artifacts/command_logs/`。退出码 0 时调用 `email.sh`；信发失败，进程仍以 0 退出。邮件里带一条可重放的命令：`cuda <GPU 编号> bash shell_script/mc-run-python.sh <模块> [参数...]`。`CUDA_VISIBLE_DEVICES` 没设置时，命令里不写 GPU 编号。别的退出码不发信。

两个启动脚本都会 `uv sync`，除非 `MC_SKIP_UV_SYNC=1`，或进程已经在 Slurm 作业里。

## 邮件

复制示例再填 SMTP。`env_email.sh` 在 gitignore 里。密码不要提交。

```bash
cp shell_script/env_email.sh.example shell_script/env_email.sh
```

示例里有 `FROM_EMAIL`、`FROM_SMTP_HOST`、`FROM_SMTP_PORT`（默认 `994`）、`FROM_SMTP_PASSWORD` 和 `TO_EMAIL`。`FROM_NAME` 可选。不设置时，邮件显示名用项目名。

```bash
bash shell_script/email.sh 0
bash shell_script/email.sh 0 -- my_exp.cli key=value
```

## 文件同步

`shell_script/file_sync/r2l.sh` 按同样的相对路径，把远程检出里的文件拉回本仓库。路径写在 `shell_script/file_sync/targets.txt`，一行一条。空行和 `#` 注释忽略。绝对路径和带 `..` 的路径直接拒绝。

默认 `rsync --dry-run`。真正复制加 `--run` 或 `-y`。远程没有的本地文件留着，因为 rsync 不带 `--delete`。

```bash
export SYNC_REMOTE=user@host:/path/to/my-exp
bash shell_script/file_sync/r2l.sh
bash shell_script/file_sync/r2l.sh --run
```

## Slurm

从仓库根提交。`shell_script/hpc/env.sh` 用 `SLURM_SUBMIT_DIR` 定 `PROJECT_ROOT`。Slurm 常把批处理文件拷到 spool 目录再跑，用 `BASH_SOURCE` 会指错地方。没设置 `SLURM_SUBMIT_DIR` 时，这个脚本报错返回。

`CUDA_HOME` 默认 `$HOME/software/cuda/cuda-12.4`。示例作业里的 `#SBATCH --partition=phys_hq` 是这台集群的分区。换集群时两处都要改。

| 脚本 | 作用 |
| --- | --- |
| `shell_script/hpc/test.slurm` | 节点冒烟：驱动和 toolkit。只有能 `import torch` 时才跑 PyTorch 矩阵乘。 |
| `shell_script/hpc/run.slurm` | 设好集群环境，再调用 `mc-run-python.sh`。 |

计算节点常常没有网，也没有代理。`sbatch` 之前在登录节点 `uv sync`。作业里 `MC_SKIP_UV_SYNC` 默认已经是 `1`。

```bash
mkdir -p artifacts/logs/slurm
sbatch shell_script/hpc/test.slurm
sbatch shell_script/hpc/run.slurm -- my_exp.cli
```
