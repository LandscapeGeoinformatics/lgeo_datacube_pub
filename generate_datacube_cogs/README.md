# Scripts for generating public COGs

This directory contains the scripts used for generating public data cube COGs from the tiles stored in the internal Google cloud buckets. The scripts are run on the UTHPC platform.

We use the following scripts:
* [generate_cog_from_seasonal_vrt.sh](./generate_cog_from_seasonal_vrt.sh): Generates a single seasonal COG from the corresponding VRT created by [stac_vrt_workflow.py](./stac_vrt_workflow.py).
* [generate_cog_topo.sh](./generate_cog_topo.sh): Generates COGs for Estonian topographic indices.
* [prepare_seasonal_cogs_parallel.sh](./prepare_seasonal_cogs_parallel.sh): Generates all seasonal COGs for a spectral index for the corresponding year. Uses [generate_cog_from_seasonal_vrt.sh](./generate_cog_from_seasonal_vrt.sh).
* [resample_landsat.sh](./resample_landsat.sh): Resamples the original 30 m Landsat tiles in the Google bucket to 10 m tiles to match with Sentinel images.
* [stac_vrt_workflow.py](./stac_vrt_workflow.py): Helper script for querying the STAC-indexed internal Google bucket to generate seasonal VRT mosaics based on collection IDs.