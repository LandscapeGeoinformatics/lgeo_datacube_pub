#!/bin/bash
#SBATCH --job-name=prepare_div_calc_input
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee
#SBATCH --output=prepare_div_calc_input_%j.out
#SBATCH --error=prepare_div_calc_input_%j.err
#SBATCH --chdir=/path/to/spectral_diversity

# Load Python
module load python/3.10.10

# Activate Micromamba environment
source ~/.bashrc
micromamba activate hpc

# Make Google application credentials accessible
source /path/to/source_svc.sh

# Input arguments
START_DATE=$1
END_DATE=$2
PAD_CELLS=1000

# Output directory
OUT_DIR="./01_data/${START_DATE}_${END_DATE}"

# Submit the Python script with a micromamba env
bash prepare_div_calc_input_gdal.sh "$START_DATE" "$END_DATE" "$OUT_DIR" "$PAD_CELLS"
