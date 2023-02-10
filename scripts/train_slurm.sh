#!/bin/bash

#SBATCH -A sds-rise
#SBATCH --partition=gpu
#SBATCH --gres=gpu:a100:4
#SBATCH --ntasks-per-node=4 # need to match number of gpus
#SBATCH -t 48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=128GB # need to match batch size.
#SBATCH -J motif_precls_exmp_pcpl_baseline # TODO: CHANGE THIS
#SBATCH -o /home/pct4et/dlfe/log/%x-%A.out
#SBATCH -e /home/pct4et/dlfe/log/%x-%A.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=pct4et@virginia.edu
#SBATCH --exclude=udc-an28-1,udc-an28-7

timestamp() {
  date +"%Y-%m-%d%H%M%S"
}

error_exit()
{
#   ----------------------------------------------------------------
#   Function for exit due to fatal program error
#       Accepts 1 argument:
#           string containing descriptive error message
#   Source: http://linuxcommand.org/lc3_wss0140.php
#   ----------------------------------------------------------------
    echo "$(timestamp) ERROR ${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    echo "$(timestamp) ERROR ${PROGNAME}: Exiting Early."
    exit 1
}

error_check()
{
#   ----------------------------------------------------------------
#   This function simply checks a passed return code and if it is
#   non-zero it returns 1 (error) to the calling script.  This was
#   really only created because I needed a method to store STDERR in
#   other scripts and also check $? but also leave open the ability
#   to add in other stuff, too.
#
#   Accepts 1 arguments:
#       return code from prior command, usually $?
#  ----------------------------------------------------------------
    TO_CHECK=${1:-0}

    if [ "$TO_CHECK" != '0' ]; then
        return 1
    fi

}

export PROJECT_DIR=${HOME}/dlfe
export MODEL_NAME="${SLURM_JOB_ID}_${SLURM_JOB_NAME}"
export LOGDIR=${PROJECT_DIR}/log
export DATA_DIR_VG_RCNN=/project/sds-rise/zhanwen/datasets
MODEL_DIRNAME=${PROJECT_DIR}/checkpoints/${MODEL_NAME}/

if [ -d "$MODEL_DIRNAME" ]; then
  error_exit "Aborted: ${MODEL_DIRNAME} exists." 2>&1 | tee -a ${LOGDIR}/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.log
else
  module purge
  module load singularity

  export BATCH_SIZE=64
  export MAX_ITER=10000
  export SINGULARITYENV_PREPEND_PATH="${HOME}/.conda/envs/dlfe/bin:/opt/conda/condabin"
  export CONFIG_FILE=configs/e2e_relation_X_101_32_8_FPN_1x.yaml
  export NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
  export USE_GT_BOX=True
  export USE_GT_OBJECT_LABEL=True
  export PRE_VAL=True
  export PORT=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
  export WEIGHT="''"

  singularity exec --nv --env LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:${HOME}/.conda/envs/dlfe/lib" docker://pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel ${PROJECT_DIR}/scripts/train.sh
fi
