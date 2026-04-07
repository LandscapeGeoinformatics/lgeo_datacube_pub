# Scripts for calculating nodata statistics

This directory contains the scripts used for calculating nodata statistics for the seasonal spectral indices in the data cube.

We use the following scripts:
* [calc_nodata.py](./calc_nodata.py): Calculates seasonal nodata percentages of public COGs for all years in Python. Use command line argument `--source` to define the source dataset, i.e. `landsat`, `sentinel1` or `sentinel2`. The output is a CSV for each task, i.e. seasonal spectral index.
* [calc_nodata.sh](./calc_nodata.sh): Job submission script for running the nodata calculation on the HPC.
* [combine_nodata_csv.py](./combine_nodata_csv.py): Combines all nodata statistics in the working folder into a single CSV for each source. Use command line argument `--source` to define the source dataset, i.e. `landsat`, `sentinel1` or `sentinel2`.
* [explore_nodata_stats.ipynb](./explore_nodata_stats.ipynb): Explores the full ranges of the nodata statistics in a Jupyter notebook.