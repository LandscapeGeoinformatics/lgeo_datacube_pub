# this script was used to calculate nodata pixel of Landsat COG stored in HPCS S3
# the COGs stored there were old version, where gap-filling was not implemented properly
# that being said, those 'unfilled' pixels are basically nodata pixels
# this method is an alternative to exporting separate nodata tiles, which would take tremendous time
# estonia 500m buffer was used as the reference for baseline nodata pixel calculation

import argparse
import os

import rasterio
import numpy as np
import pandas as pd


parser = argparse.ArgumentParser()
parser.add_argument(
    "--source",
    required=True,
    choices=["lsat", "sentinel1", "sentinel2"]
)
args = parser.parse_args()
source = args.source

task_id = int(os.environ["SLURM_ARRAY_TASK_ID"])

# Get short source name for file paths
if source == "lsat":
    source_short = "lsat"
elif source == "sentinel1":
    source_short = "s1"
elif source == "sentinel2":
    source_short = "s2"

years = [
    2017,
    2018,
    2019,
    2020,
    2021,
    2022,
    2023,
    2024,
    2025
]

if source in ["lsat", "sentinel2"]:
    indices = [
        "ndvi",
        "bsi",
        "evi",
        "savi",
        "fvc",
        "ndmi",
        "ndwi",
        "lai",
        "gndvi"
    ]
elif source == "sentinel1":
    indices = [
        "rvi"
    ]

seasons = {
    "spring": ("04-01", "05-31"),
    "summer": ("06-01", "08-31"),
    "autumn": ("09-01", "10-31")
}

rasters = []
for y in years:
    for season_name, (start, end) in seasons.items():
        season_str = f"{y}-{start}_{y}-{end}"
        for i in indices:
            path = (
                f"https://s3.hpc.ut.ee/geokuup/estonia/"
                f"{source}/{i}/{y}/"
                f"est_{source_short}_{i}_median_{season_str}_cog.tif"
            )
            rasters.append((y, season_name, season_str, i, path))

year, season, season_str, index, raster_path = rasters[task_id]
url = f"/vsicurl/{raster_path}"

reference_subtractor = 504080576 # amount of nodata pixel in the reference est raster (inland water body, sea)
reference_valid = 453099424 # amount of land pixel only

total_pixels = 0
nodata_pixels = 0

try:
    with rasterio.open(url) as src:
        for _, window in src.block_windows(1):
            data = src.read(1, window=window, masked=True)  # masked=True for NoData
            nodata_pixels += np.sum(data.mask)
            total_pixels += data.size

    # Compute reference-based percent nodata
    true_nodata_pixels = nodata_pixels - reference_subtractor
    percent_nodata = (true_nodata_pixels * 100) / reference_valid

    # Save per-task CSV
    df = pd.DataFrame([{
        "source": source,
        "year": year,
        "season": season,
        "season_str": season_str,
        "index": index,
        "total_pixels": total_pixels,
        "nodata_pixels": nodata_pixels,
        "true_nodata_pixels": true_nodata_pixels,
        "valid_pixels": total_pixels - true_nodata_pixels,
        "percent_nodata": percent_nodata
        
    }])

    output_csv = f"nodata_stats_{source}_{task_id}.csv"
    df.to_csv(output_csv, index=False)
    print(f"Finished {year}-{index}, saved to {output_csv}")

except Exception as e:
    print(f"Error processing {year}-{index}: {e}")
