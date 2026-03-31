# Scripts for calculating spectral indices

This directory contains the scripts used for calculating various seasonal spectral indices for the data cube. The indices are calculated from Landsat, Sentinel-1 and Sentinel-2 image collections hosted by Google Earth Engine (GEE). All indices are exported as 10000 by 10000 px tiles. The scripts can generate tiles for Estonia, the Baltics and Europe.

We use the following scripts:
* [calc_landsat_indices.ipynb](./calc_landsat_indices.ipynb): Calculates seasonal spectral indices for Landsat by combining Landsat 8 and Landsat 9 collections.
* [calc_s1_indices.ipynb](./calc_s1_indices.ipynb): Calculates seasonal RVI and VVVHR indices for Sentinel-1.
* [calc_s2_indices.ipynb](./calc_s2_indices.ipynb): Calculates seasonal spectral indices for Sentinel-2.
* [speckle_filter.py](./speckle_filter.py): Contains the speckle filter function used in [calc_s1_indices.ipynb](./calc_s1_indices.ipynb).
* [utils.py](./utils.py): Contains helper functions used for tiling and metadata handling in the spectral index calculation workflows.