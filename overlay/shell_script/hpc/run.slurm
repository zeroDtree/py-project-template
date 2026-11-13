#!/usr/bin/env bash
# Change --partition for your cluster. phys_hq is this site's default.
#SBATCH --job-name=mc-run
#SBATCH --partition=phys_hq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=artifacts/logs/slurm/mc-run-%j.out
#SBATCH --error=artifacts/logs/slurm/mc-run-%j.err

# Training / eval SLURM job: cluster env + mc-run-python.sh (accelerate).
# Submit from the repo root; sync the venv on the login node first.
#
# Usage:
#   mkdir -p artifacts/logs/slurm
#   uv sync   # or: MC_ENABLE_PROXY=1 uv sync
#   sbatch shell_script/hpc/run.slurm -- __PACKAGE_NAME__.cli
#   sbatch --gres=gpu:2 shell_script/hpc/run.slurm -- __PACKAGE_NAME__.cli
#
# Optional overrides:
#   sbatch --time=48:00:00 --gres=gpu:4 shell_script/hpc/run.slurm -- __PACKAGE_NAME__.cli
#   sbatch --export=ALL,CUDA_HOME=$HOME/software/cuda/cuda-12.4,MC_SKIP_UV_SYNC=0 \
#     shell_script/hpc/run.slurm -- __PACKAGE_NAME__.cli

set -euo pipefail

# Slurm may run a spool copy of this script; resolve paths via SLURM_SUBMIT_DIR.
source "${SLURM_SUBMIT_DIR}/shell_script/hpc/env.sh"

# Sync on login node before submit; compute nodes often lack network/proxy.
export MC_SKIP_UV_SYNC="${MC_SKIP_UV_SYNC:-1}"

if [[ $# -lt 1 ]]; then
  echo "Usage: sbatch shell_script/hpc/run.slurm -- <python_module> [args...]" >&2
  echo "Example: sbatch shell_script/hpc/run.slurm -- __PACKAGE_NAME__.cli" >&2
  exit 1
fi

bash "${PROJECT_ROOT}/shell_script/mc-run-python.sh" "$@"
