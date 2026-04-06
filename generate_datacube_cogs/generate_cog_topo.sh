#!/bin/bash

#SBATCH --job-name=topo_indices_clip
#SBATCH --output=topo_indices_clip_%A.out
#SBATCH --error=topo_indices_clip_%A.err
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=username@ut.ee

# Load Python
module load python/3.10.10

# Activate Micromamba environment
source ~/.bashrc
micromamba activate hpc

COLLECTION_ID=$1

# Define input/output files
VRT_FILE="${COLLECTION_ID}_mosaic.vrt"
CLIPPED_TIF="${COLLECTION_ID}_clipped.tif"
NODATA_TIF="${COLLECTION_ID}_clipped_nodata.tif"
FINAL_COG="${COLLECTION_ID}_cog.tif"
REF_GRID="https://storage.googleapis.com/geo-assets/grid_tiles/est_ref_grid_500m_buffer_2025.tif"

# Generate seasonal VRT from collection
python stac_vrt_workflow.py "$COLLECTION_ID" -o "$VRT_FILE"

gdal_translate -projwin 369000.0 6635000.0 740000.0 6377000.0 -a_nodata -9999.0 -of GTiff -tr 10 10 -r bilinear -co COMPRESS=LZW -co BIGTIFF=YES "$VRT_FILE" "$CLIPPED_TIF"

# set all nodata where ELME2 ref grid is nodata
gdal_calc.py --overwrite --calc "A*(B==1)" --format GTiff --type Float32 -A "$CLIPPED_TIF" --A_band 1 -B "$REF_GRID" --co COMPRESS=LZW --co BIGTIFF=YES --NoDataValue=-9999 --outfile "$NODATA_TIF"

# convert to COG for final use
gdal_translate -of COG -co COMPRESS=LZW -co BIGTIFF=YES "$NODATA_TIF" "$FINAL_COG"

# Clean up intermediate files
rm -f "$CLIPPED_TIF" "$NODATA_TIF"