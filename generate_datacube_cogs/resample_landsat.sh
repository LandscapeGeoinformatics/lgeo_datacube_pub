#!/bin/bash
#SBATCH --job-name=resampling_landsat
#SBATCH --output=logs/resampling_landsat_%A_%a.out
#SBATCH --error=logs/resampling_landsat_%A_%a.err
#SBATCH --array=0-13          # <-- set to number_of_rasters-1
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee

# Load Python
module load python/3.10.10

# Activate Micromamba environment
source ~/.bashrc
micromamba activate hpc

# -----------------------------
# ARGUMENTS
# -----------------------------
INDEX=$1   # ndvi / ndwi / savi
YEAR=$2    # 2022 / 2023 / 2024 / 2025

if [ -z "$INDEX" ] || [ -z "$YEAR" ]; then
    echo "USAGE: sbatch --array=0-N run_landsat_index_vsigs.sh <index> <year>"
    exit 1
fi

# -----------------------------
# CONFIG
# -----------------------------
BUCKET="bucket_name"    # replace with your bucket
GPKG="grid_tiles_est_gee_grid_tiles_limited.gpkg"
LAYER="est_gee_grid_tiles_limited"

OUT_DIR="output_${INDEX}_${YEAR}_10m"
TEMP_DIR="temp_${INDEX}_${YEAR}_10m"

mkdir -p "$OUT_DIR" "$TEMP_DIR" logs

# -----------------------------
# LIST RASTERS
# -----------------------------
LIST_FILE="raster_list_${INDEX}_${YEAR}.txt"

if [[ ! -f "$LIST_FILE" ]]; then
    gsutil ls "gs://${BUCKET}/estonia_working/landsat/${INDEX}/${YEAR}/"*.tif > "$LIST_FILE"
fi

mapfile -t RASTERS < "$LIST_FILE"
TOTAL=${#RASTERS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No rasters found for ${INDEX} ${YEAR}"
    exit 1
fi

echo "Found $TOTAL rasters"

# -----------------------------
# SLURM ARRAY INDEX
# -----------------------------
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Must run as array job: sbatch --array=0-$(($TOTAL-1)) ..."
    exit 1
fi

# -----------------------------
# SELECT RASTER
# -----------------------------
GCS_RASTER="${RASTERS[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$GCS_RASTER" .tif)

echo "Processing raster: $GCS_RASTER"

# -----------------------------
# Use /vsigs/ path for GDAL
# -----------------------------
IN_RASTER="/vsigs/${GCS_RASTER#gs://}"

# -----------------------------
# Extract tile ID
# -----------------------------
if [[ "$BASENAME" =~ _([0-9]{1,2})_30m ]]; then
    TILE_ID="${BASH_REMATCH[1]}"
else
    echo "ERROR: Cannot extract tile ID from $BASENAME"
    exit 1
fi

echo "Tile ID = $TILE_ID"

# -----------------------------
# Step 1 — Resample to 10 m
# -----------------------------
TEMP_RASTER="$TEMP_DIR/${BASENAME}_10m_tmp.tif"

gdalwarp \
    -tr 10 10 \
    -r nearest \
    -multi -wo NUM_THREADS=$SLURM_CPUS_PER_TASK \
    -of GTiff \
    "$IN_RASTER" "$TEMP_RASTER"

echo "Resampled: $TEMP_RASTER"

# -----------------------------
# Step 2 — Clip to tile & output COG
# -----------------------------
OUT_NAME="${BASENAME/_30m/}.tif"
OUT_RASTER="$OUT_DIR/$OUT_NAME"

gdalwarp \
    -cutline "$GPKG" \
    -cl "$LAYER" \
    -cwhere "tile_id='${TILE_ID}'" \
    -crop_to_cutline \
    -multi -wo NUM_THREADS=$SLURM_CPUS_PER_TASK \
    -of COG \
    -co COMPRESS=LZW \
    -co OVERVIEWS=AUTO \
    -co NUM_THREADS=ALL_CPUS \
    "$TEMP_RASTER" "$OUT_RASTER"

echo "COG written → $OUT_RASTER"

# -----------------------------
# Step 3 — Remove temp
# -----------------------------
rm "$TEMP_RASTER"
echo "Removed temporary raster"
echo "Finished tile $TILE_ID"
