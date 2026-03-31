#!/bin/bash
#SBATCH --job-name=nodata_calc
#SBATCH --output=logs/nodata_%A_%a.out
#SBATCH --error=logs/nodata_%A_%a.err
#SBATCH --array=0-269
#SBATCH --mem=4G
#SBATCH --time=0-0:15:00
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee

# Load Python
module load python/3.10.10

# Activate Micromamba environment
source ~/.bashrc
micromamba activate hpc

# Source dataset
SOURCE=$1

# Run Python script (reads SLURM_ARRAY_TASK_ID)
python calc_nodata.py --source $SOURCE
