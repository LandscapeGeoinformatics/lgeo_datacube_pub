import os
import sys

from osgeo import gdal
import rasterio
import numpy as np


# Get list of tile IDs to be exported
def main(start_date, end_date, tile_id, out_dir, variable):

    out_nodata = -9999

    # Clip for a specific tile
    fp_grid_tiles = (
        "https://storage.googleapis.com/geo-assets/grid_tiles/"
        "est_gee_grid_tiles_limited.gpkg"
    )
    fp_clipped = (
        f"{out_dir}/"
        f"est_s2_alpha_{start_date}_{end_date}_{tile_id}_clipped.tif"
    )
    sql = (
        f"SELECT * FROM est_gee_grid_tiles_limited WHERE tile_id='{tile_id}'"
    )
    gdal.Warp(
        fp_clipped,
        fp_vrt,
        cutlineDSName=fp_grid_tiles,
        cutlineSQL=sql,
        cropToCutline=True,
        dstNodata=out_nodata,
        creationOptions=["COMPRESS=LZW", "PREDICTOR=3"]
    )

    with rasterio.open(fp_clipped) as src:
    
        # Convert to integer
        data = src.read(1)
        data = (
            np.where(data != out_nodata, data.round(3) * 1000, out_nodata)
            .astype("int16")
        )
        
        # Update profile
        profile = src.profile
        profile.update(
            dtype="int16",
            nodata=out_nodata,
            compress="lzw",
            predictor=2
        )

        # Write to raster
        out_fp = (
            f"{out_dir}/"
            f"est_s2_{variable}_{start_date}_{end_date}_{tile_id}.tif"
            )
        with rasterio.open(out_fp, "w", **profile) as dst:
            dst.write(data, 1)
    
    # Delete intermediate clipped file
    os.remove(fp_clipped)


if __name__ == "__main__":

    # Input arguments
    start_date = sys.argv[1]
    end_date = sys.argv[2]
    in_dir = sys.argv[3]
    out_dir = sys.argv[4]

    # Create output directory
    os.makedirs(out_dir, exist_ok=True)

    # Tile IDs
    tile_ids = [
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12",
        "13",
        "14",
        "15",
        "18",
        "19"
    ]

    # Build VRT mosaic of all tiles
    vrt_input = []
    stat = "mean"
    variable = "alpha_diversity"
    for tile_id in tile_ids:
        in_fp = (
            f"{in_dir}/{start_date}_{end_date}/{tile_id}/"
            "biodivMapR_LAI_SAVI_NDWI1_NDVI/shannon/"
            f"_{tile_id}_{stat}.tiff_mosaic.tiff"
        )
        vrt_input.append(in_fp)
    fp_vrt = (
        f"{out_dir}/"
        f"est_s2_{variable}_{start_date}_{end_date}_mosaic.vrt"
    )
    vrt = gdal.BuildVRT(fp_vrt, vrt_input)
    vrt = None

    # Run main function
    for tile_id in tile_ids:
        try:
            main(start_date, end_date, tile_id, out_dir, variable)
        except Exception as e:
            print(f"Error processing tile {tile_id}: {e}")
    
    # Delete intermediate VRT file
    os.remove(fp_vrt)
