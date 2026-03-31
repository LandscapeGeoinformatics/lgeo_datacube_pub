import sys
import os

import xarray as xr
import rioxarray
from rasterio import RasterioIOError


# Get list of tile IDs to be exported
def get_export_tile_ids(short_region_name):
    if short_region_name == "est":
        return [
            "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", 
            "14", "15", "18", "19"
        ]
    elif short_region_name == "bal":
        return [
            "02", "03", "07", "08", "12", "13", "17", "18"
        ]
    elif short_region_name == "eur":
        return [
            "07", "08", "09", "10", "11", "12", "17", "18", "19", "20", 
            "21", "22", "23", "29", "30", "31", "32", "33", "39", "40", 
            "41", "42", "48", "49", "50", "51", "58"
        ]


# Get dictionary of export periods for region
def get_export_periods(years, short_region_name):
    
    export_periods = {}
    
    # Loop over years
    for year in years:

        # Use three seasons for Estonia
        if short_region_name == "est":
            start_dates = [
                f"{year}-04-01",
                f"{year}-06-01",
                f"{year}-09-01"
            ]
            end_dates = [
                f"{year}-05-31",
                f"{year}-08-31",
                f"{year}-10-31"
            ]

        # Use single growing season for Baltics and Europe
        elif short_region_name in ["bal", "eur"]:
            start_dates = [
                f"{year}-05-01"
            ]
            end_dates = [
                f"{year}-09-30"
            ]
            
        export_periods[year] = {
            "start_dates": start_dates,
            "end_dates": end_dates
        }
        
    return export_periods


# Get long region name
def get_long_region_name(short_region_name):
    if short_region_name == "est":
        return "estonia"
    elif short_region_name == "bal":
        return "baltics"
    elif short_region_name == "eur":
        return "europe"


# Get long dataset name
def get_long_ds_name(short_ds_name):
    if short_ds_name == "s1":
        return "sentinel1"
    elif short_ds_name == "s2":
        return "sentinel2"
    elif short_ds_name == "esa_worldcover":
        return "esa_worldcover_v100"
    elif short_ds_name in [
        "copernicus_glo_dem_30",
        "era5",
        "hydrography90m",
        "soilgrids",
        "worldpop"
    ]:
        return short_ds_name


# Export range image for tile
def export_range_image(min_file, max_file, range_file):
    
    # Empty dataset
    ds = xr.Dataset()
    
    # Read minimum image as variable
    try:
        ds[f"{variable}_min"] = (
            rioxarray
            .open_rasterio(min_file)
            .squeeze()
        )
    except RasterioIOError:
        print(f"File {min_file} does not exist!")
    
    # Read maximum image as variable
    try:
        ds[f"{variable}_max"] = (
            rioxarray
            .open_rasterio(max_file)
            .squeeze()
        )
    except RasterioIOError:
        print(f"File {max_file} does not exist!")

    try:
        
        # Nodata value
        nodata_val = ds[f"{variable}_max"].rio.nodata
        
        # Data type
        dtype = ds[f"{variable}_max"].dtype
    
        # Calculate range
        ds[f"{variable}_range"] = xr.where(
            (
                (ds[f"{variable}_max"] != nodata_val) & 
                (ds[f"{variable}_min"] != nodata_val)
            ), 
            ds[f"{variable}_max"] - ds[f"{variable}_min"],
            ds[f"{variable}_max"].rio.nodata
        ).astype(dtype)
    
        # Set nodata value
        ds[f"{variable}_range"].rio.write_nodata(nodata_val, inplace=True)
    
        # Export range image
        ds[f"{variable}_range"].rio.to_raster(
            range_file,
            tiled=True,
            windowed=True,
            compress="LZW",
            predictor=2,
            overwrite=True,
            dtype=dtype,
            nodata=nodata_val
        )

        print(f"File {range_file} exported!")

    except:
        print("Cannot calculate range!")


if __name__ == "__main__":

    # Input arguments
    bucket = sys.argv[1]
    out_dir = sys.argv[2]
    short_region_name = sys.argv[3]
    short_ds_name = sys.argv[4]
    variable = sys.argv[5]
    year = sys.argv[6]

    # Create output directory
    os.makedirs(out_dir, exist_ok=True)

    # Prefix for collection
    long_region_name = get_long_region_name(short_region_name)
    long_ds_name = get_long_ds_name(short_ds_name)
    prefix = f"{long_region_name}/{long_ds_name}/{variable}/{year}/"

    # Dictionary of time periods
    export_periods = get_export_periods([year], short_region_name)

    # Tile IDs
    export_tile_ids = get_export_tile_ids(short_region_name)

    # Start dates
    start_dates = export_periods[year]["start_dates"]

    # End dates
    end_dates = export_periods[year]["end_dates"]

    # Loop over time periods
    for start_date, end_date in zip(start_dates, end_dates):
        
        # Loop over grid tile IDs
        for tile_id in export_tile_ids:

            # Minimum image filename
            filename_parts = [
                short_region_name,
                short_ds_name,
                variable,
                "min",
                start_date,
                end_date,
                tile_id
            ]
            min_file = (
                f"/vsigs/{bucket}/{prefix}" + 
                "_".join(filename_parts) + 
                ".tif"
            )
            
            # Maximum image filename
            filename_parts[3] = "max"
            max_file = (
                f"/vsigs/{bucket}/{prefix}" + 
                "_".join(filename_parts) + 
                ".tif"
            )
            filename_parts[3] = "range"

            # Range image filename
            range_file = (
                f"{out_dir}/" + 
                "_".join(filename_parts) + 
                ".tif"
            )

            # Export range image
            if not os.path.exists(range_file):
                export_range_image(min_file, max_file, range_file)
            else:
                print(f"Skipping export as file {range_file} exists!")
