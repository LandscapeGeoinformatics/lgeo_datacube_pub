#!/bin/bash
set -euo pipefail

START_DATE=$1
END_DATE=$2
OUT_DIR=$3
PAD_CELLS=$4

REGION="estonia"
YEAR=${START_DATE:0:4}
RES=10

GRID_GPKG="https://storage.googleapis.com/geo-assets/grid_tiles/est_gee_grid_tiles_limited_pad.gpkg"
GRID_LAYER="est_gee_grid_tiles_limited_pad"

mkdir -p "$OUT_DIR"

BANDS=(b1 b2 b3 b4 b5 b6 b7 b8 b8a b9 b11 b12)
TILES=("04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "18" "19")

echo "Building seasonal VRTs per band"

for BAND in "${BANDS[@]}"; do
    VRT="$OUT_DIR/${BAND}_${START_DATE}_${END_DATE}.vrt"
    rm -f "$VRT"

    INPUTS=()
    for TILE in "${TILES[@]}"; do
        INPUTS+=(
            "/vsigs/bucket_name/${REGION}/sentinel2/${BAND}/${YEAR}/est_s2_${BAND}_median_${START_DATE}_${END_DATE}_${TILE}.tif"
        )
    done

    gdalbuildvrt -resolution user -tr 10 10 -r nearest -vrtnodata -9999 "$VRT" "${INPUTS[@]}"
done

echo "Creating padded stacks per tile"

for TILE in "${TILES[@]}"; do
    echo "Processing tile $TILE"

    BAND_TIFS=()

    for BAND in "${BANDS[@]}"; do
        IN_VRT="$OUT_DIR/${BAND}_${START_DATE}_${END_DATE}.vrt"
        OUT_BAND="$OUT_DIR/tmp_${BAND}_${TILE}.tif"

        gdalwarp -cutline "$GRID_GPKG" -csql "SELECT * FROM $GRID_LAYER WHERE tile_id='${TILE}'" -crop_to_cutline -tr 10 10 -tap -r nearest -srcnodata -9999 -dstnodata -9999 -overwrite "$IN_VRT" "$OUT_BAND"

        BAND_TIFS+=("$OUT_BAND")
    done

    STACK_VRT="$OUT_DIR/tmp_stack_${TILE}.vrt"
    FINAL_TIF="$OUT_DIR/est_s2_median_${START_DATE}_${END_DATE}_${TILE}_pad.tif"

    gdalbuildvrt -separate "$STACK_VRT" "${BAND_TIFS[@]}"

    gdal_translate -co COMPRESS=LZW -co PREDICTOR=2 -co BIGTIFF=YES "$STACK_VRT" "$FINAL_TIF"

    rm -f "$STACK_VRT" "${BAND_TIFS[@]}"
done

echo "Cleaning up seasonal VRTs"
rm -f "$OUT_DIR"/*_"${START_DATE}_${END_DATE}.vrt"
