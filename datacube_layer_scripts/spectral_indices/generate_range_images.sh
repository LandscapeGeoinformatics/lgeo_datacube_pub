#!/bin/bash
#SBATCH --job-name=generate_range_images
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee
#SBATCH --output=generate_range_images_%j.out
#SBATCH --error=generate_range_images_%j.err

# Load Python
module load python/3.10.10

# Make Google application credentials accessible
source source_svc.sh

# Input arguments
BUCKET="bucket_name"
LONG_REGION_NAME=$1
LONG_DS_NAME=$2
VARIABLE=$3
YEAR=$4

# Get short region name
if [[ "$LONG_REGION_NAME" == "estonia" ]]; then
    SHORT_REGION_NAME="est"
elif [[ "$LONG_REGION_NAME" == "baltics" ]]; then
    SHORT_REGION_NAME="bal"
elif [[ "$LONG_REGION_NAME" == "europe" ]]; then
    SHORT_REGION_NAME="eur"
else
    echo "Unknown region: $LONG_REGION_NAME"
    exit 1
fi

# Get short dataset name
if [[ "$LONG_DS_NAME" == "sentinel1" ]]; then
    SHORT_DS_NAME="s1"
elif [[ "$LONG_DS_NAME" == "sentinel2" ]]; then
    SHORT_DS_NAME="s2"
else
    echo "Unknown dataset: $LONG_DS_NAME"
    exit 1
fi

# Output directory
OUT_DIR="path/to/range_images/${LONG_REGION_NAME}/${LONG_DS_NAME}/${VARIABLE}/${YEAR}"

# Submit the Python script with a micromamba env
micromamba run -n hpc python generate_range_images.py $BUCKET $OUT_DIR $SHORT_REGION_NAME $SHORT_DS_NAME $VARIABLE $YEAR
