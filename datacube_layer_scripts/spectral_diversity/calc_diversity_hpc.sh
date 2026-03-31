#!/bin/bash
#SBATCH --job-name=calc_diversity_hpc
#SBATCH --output=calc_diversity_hpc_%j.out
#SBATCH --error=calc_diversity_hpc_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --time=72:00:00
#SBATCH --partition=amd
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee

# Initialize micromamba
eval "$(micromamba shell hook -s bash)"

# Activate R environment
micromamba activate spectraldiv

# Confirm that R is available
which Rscript
Rscript --version

# Move to project directory
cd $SLURM_SUBMIT_DIR

# Input arguments
START_DATE=$1
END_DATE=$2
TILE_ID=$3

# Print run identifiers to error log
echo "JOB_ID=${SLURM_JOB_ID} HOST=$(hostname) START_DATE=${START_DATE} END_DATE=${END_DATE} TILE_ID=${TILE_ID}" >&2

# Cell size for AOI tiling
CELLSIZE=30000

# Run R script
Rscript calc_diversity_hpc.R $CELLSIZE $START_DATE $END_DATE $TILE_ID
