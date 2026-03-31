# Code supplement: National data cube for environmental modelling and monitoring

This repository contains scripts for processing and managing datacube layers in the data cube project published by the Landscape Geoinformatics Lab: https://geokuup.ee/estonia?locale=en.

## Directories and files

**`datacube_layer_scripts/`**:
- **`calc_nodata/`**: Scripts for calculating nodata statistics for public COGs.
- **`prepare_features/ERA5_overlay`**: Scripts for downloading ERA5 data and generating tiled climate variables in GEE.
- **`spectral_diversity/`**: Scripts for calculating spectral diversity based on seasonal median composites of Sentinel-2 bands.
- **`spectral_indices/`**: Scripts for generating tiled spectral index images in GEE.
- **`source_svc.sh/`**: Set path for Google credentials. This helper script is used for granting Google bucket access during HPC jobs.