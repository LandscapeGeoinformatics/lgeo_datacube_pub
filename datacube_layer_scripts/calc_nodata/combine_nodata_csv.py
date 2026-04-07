import argparse
import glob

import pandas as pd

 
parser = argparse.ArgumentParser()
parser.add_argument(
    "--source",
    required=True,
    choices=["landsat", "sentinel1", "sentinel2"]
)
args = parser.parse_args()
source = args.source

csv_files = glob.glob(f"*{source}*.csv")

df_csv_append = pd.DataFrame()

for file in csv_files:
    df = pd.read_csv(file)
    df_csv_append = pd.concat([df_csv_append, df], ignore_index=True)

# Sort based on season
df_csv_append = df_csv_append.sort_values(
    by=["year", "index", "season_str"]
).reset_index(drop=True)

df_csv_append.to_csv(f"nodata_calc_combined_{source}.csv", index=False)
