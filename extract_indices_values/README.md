# Demo notebook for extracting values from COGs

[![Open In Collab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/LandscapeGeoinformatics/lgeo_datacube_pub/blob/main/extract_indices_values/extract_pixel_value_stac.ipynb)

This directory contains an example notebook for extracting values and zonal statistics from various environmental layers, such as satellite-derived seasonal spectral indices and Digital Elevation Model (DEM)-derived layers, available in the public data cube, using points and polygons. The scripts leverage STAC queries to access specified index collections.

We provide the following files:
* [extract_pixel_value_stac.ipynb](./extract_pixel_value_stac.ipynb): Demo notebook to extract pixel values for given points and polygons from COGs.
* `demo_point.gpkg`: Points used in the demo notebook
* `demo_area.gpkg`: Polygons used in the demo notebook

To run the demo, the following Python libraries are required:
```
geopandas
rasterstat
pystac_client
```
