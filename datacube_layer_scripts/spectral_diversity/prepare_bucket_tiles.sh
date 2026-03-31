#!/bin/bash
#SBATCH --job-name=prepare_bucket_tiles
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee
#SBATCH --output=prepare_bucket_tiles_%j.out
#SBATCH --error=prepare_bucket_tiles_%j.err
#SBATCH --chdir=/path/to/spectral_diversity

# Load Python
module load python/3.10.10

# Make Google application credentials accessible
source /path/to/source_svc.sh

# Input arguments
START_DATE=$1
END_DATE=$2
IN_DIR=$3

# Output directory
YEAR=$(date -d "$START_DATE" +%Y)
OUT_DIR="./bucket_tiles_unmasked/${YEAR}"

# Submit the Python script with a micromamba env
micromamba run -n hpc python prepare_bucket_tiles.py $START_DATE $END_DATE $IN_DIR $OUT_DIR
