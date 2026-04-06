#!/bin/bash

#SBATCH --job-name=prepare_seasonal_cogs_parallel
#SBATCH --output=prepare_seasonal_cogs_parallel_%A_%a.out
#SBATCH --error=prepare_seasonal_cogs_parallel_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=0-2
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee

# Load Python
module load python/3.10.10

# Activate Micromamba environment
source ~/.bashrc
micromamba activate hpc

# Input arguments
BUCKET="bucket_name"
LONG_REGION_NAME=$1
LONG_DS_NAME=$2
VARIABLE=$3
YEAR=$4
OUTPUT_DIR=$5

# Determine data type based on variable
if [[ "$VARIABLE" == "lai" ]]; then
    DTYPE="Int32"
else
    DTYPE="Int16"
fi

# Optional statistic
STAT=$6
STAT="$(echo -n "$STAT" | xargs)"

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

# Input collection ID
COLLECTION_ID="${BUCKET}-${LONG_REGION_NAME}-${LONG_DS_NAME}-${VARIABLE}-${YEAR}"

# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"

# Seasons to process
SEASONS=("${YEAR}-04-01_${YEAR}-05-31" "${YEAR}-06-01_${YEAR}-08-31" "${YEAR}-09-01_${YEAR}-10-31")

# Get the current season based on the Slurm array task ID
SEASON=${SEASONS[$SLURM_ARRAY_TASK_ID]}

# Determine filter string and output prefix based on statistic
if [[ -z "$STAT" ]]; then
    
    # No statistic in filenames or STAC filter
    FILTER_STRING="${SEASON}"
    OUT_PREFIX="${SHORT_REGION_NAME}_${SHORT_DS_NAME}_${VARIABLE}_${SEASON}"

else
    echo "Statistic provided: $STAT"
    
    # Include statistic in filenames and filter
    FILTER_STRING="${STAT}_${SEASON}"
    OUT_PREFIX="${SHORT_REGION_NAME}_${SHORT_DS_NAME}_${VARIABLE}_${STAT}_${SEASON}"

fi

# Define output VRT file for the season
VRT_FILE="${OUTPUT_DIR}/${OUT_PREFIX}_mosaic.vrt"

# Generate seasonal VRT from collection
python stac_vrt_workflow.py "$COLLECTION_ID" -f="$FILTER_STRING" -o "$VRT_FILE"

# Generate COG from seasonal VRT
bash generate_cog_from_seasonal_vrt.sh "$VRT_FILE" "$DTYPE"

# Delete VRT
rm -f "$VRT_FILE"
