# Code supplement: National data cube for environmental modelling and monitoring

This repository contains scripts for processing and managing datacube layers in the data cube project published by the Landscape Geoinformatics Lab: https://geokuup.ee/estonia?locale=en.

Zenodo repository: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19483465.svg)](https://doi.org/10.5281/zenodo.19483465)

## Directories and files

[datacube_layer_scripts](./datacube_layer_scripts):
- [calc_nodata](./datacube_layer_scripts/calc_nodata): Scripts for calculating nodata statistics for public COGs.
- [prepare_features/ERA5_overlay](./datacube_layer_scripts/prepare_features/ERA5_overlay): Scripts for downloading ERA5 data and generating tiled climate variables in GEE.
- [spectral_diversity](./datacube_layer_scripts/spectral_diversity): Scripts for calculating spectral diversity based on seasonal median composites of Sentinel-2 bands.
- [spectral_indices](./datacube_layer_scripts/spectral_indices): Scripts for generating tiled spectral index images in GEE.
- [source_svc.sh](./datacube_layer_scripts/source_svc.sh): Set path for Google credentials. This helper script is used for granting Google bucket access during HPC jobs.

[generate_datacube_cogs](./generate_datacube_cogs): Scripts for generating public COGs from internal Google bucket tiles.

[extract_indices_values](./extract_indices_values): Scripts for extracting values and statistics for points and polygons from public spectral index COGs via STAC.