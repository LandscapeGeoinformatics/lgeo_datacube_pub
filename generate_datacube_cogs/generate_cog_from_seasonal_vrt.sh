#!/bin/bash

# Exit on error
set -e

# Function to display usage
usage() {
    echo "Usage: $0 VRT_FILE DTYPE"
    echo "Example: $0 ./seasonal_cogs/2025/est_s2_ndvi_median_2025-09-01_2025-10-31_mosaic.vrt Int16"
    exit 1
}

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if VRT file and data type are provided
if [ $# -ne 2 ]; then
    usage
fi

# Function to check Google Cloud credentials
check_gcp_credentials() {
    if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        log "Error: GOOGLE_APPLICATION_CREDENTIALS environment variable is not set"
        echo "Please set it with: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/credentials.json"
        exit 1
    fi

    if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        log "Error: Credentials file $GOOGLE_APPLICATION_CREDENTIALS does not exist"
        exit 1
    fi
}

# Validate GCP credentials before proceeding
check_gcp_credentials

# Input arguments
VRT_FILE=$1
DTYPE=$2

# Define input/output files
OUTPUT_DIR=$(dirname "$VRT_FILE")
BASENAME=$(basename "$VRT_FILE" _mosaic.vrt)
CLIPPED_TIF="${OUTPUT_DIR}/${BASENAME}_clipped.tif"
NODATA_TIF="${OUTPUT_DIR}/${BASENAME}_clipped_nodata.tif"
FINAL_COG="${OUTPUT_DIR}/${BASENAME}_cog.tif"
REF_GRID="https://storage.googleapis.com/geo-assets/grid_tiles/est_ref_grid_500m_buffer_2025.tif"

gdal_translate -projwin 369000.0 6635000.0 740000.0 6377000.0 -a_nodata -9999.0 -of GTiff -co COMPRESS=LZW -co BIGTIFF=YES "$VRT_FILE" "$CLIPPED_TIF"

# set all nodata where ELME2 ref grid is nodata
gdal_calc.py --overwrite --calc "A*(B==1)" --format GTiff --type "$DTYPE" -A "$CLIPPED_TIF" --A_band 1 -B "$REF_GRID" --co COMPRESS=LZW --co BIGTIFF=YES --NoDataValue=-9999 --outfile "$NODATA_TIF"

# convert to COG for final use
gdal_translate -of COG -co COMPRESS=LZW -co BIGTIFF=YES "$NODATA_TIF" "$FINAL_COG"

# Clean up intermediate files
log "Cleaning up intermediate files..."
rm -f "$CLIPPED_TIF" "$NODATA_TIF"

log "Processing complete. Final output: $FINAL_COG"

log "Please upload to target location: gcloud storage cp $FINAL_COG gs://geo-assets/dcube_pub/"
