ERA5 only has data until 2020, however, data until 2024 is needed. Therefore, the data for the missing years was downloaded from the Climate Data Store as netcdfs using the CDS API (script ‘01_cds_api_request.ipynb’). As the ERA5 data for the year 2020 differed from ERA5 Land by 0.5 m, it was also downloaded from the Climate Data Store. 
Netcdfs cannot be ingested into GEE, but geotiffs can. Therefore, a script was written to extract each timeslice (each month) and to save it as a geotiff file (script ‘02_nc_to_gtiffs.ipynb‘), to be later ingested into GEE and created into an image collection. 
To avoid manual work of uploading each geotiff on the bucket through the web interface, the google cloud command line tool was used (step 3). 
As the bucket’s ‘isaac_shared’ location is specified as Finland, the rasters cannot be directly ingested into GEE from it, because GEE asks for a US timezone. Therefore, a workaround is to upload the geotiffs to GEE as assets from the bucket (script ‘04_bucket_to_gee_asset.ipynb‘). For this, the earthengine command line tool was used, which is installed together with the earthengine python API. 
Script ‘05_ERA5_overlay_temp_prec.ipynb’ creates ERA5 and ERA5 Land overlay, where land areas have the information from ERA5 Land (higher resolution), and the sea areas are filled with ERA5 (lower resolution). It uses the GEE comand The result – 10 000 x 10 000 cell tiles in Baltic TM (EPSG: 25884) projection with a resolution of 30 m. The tiles are created for the extent of the Baltic catchments (base grid from script 1) of the selected monitoring points. Only the tiles intersecting with the raster are exported to the bucket. Calculated parameters – mean yearly temperature, max yearly temperature, min yearly temperature, and total yearly precipitation.
The order of steps:

1.	01_cds_api_request.ipynb
2.	02_nc_to_gtiffs.ipynb
3.	(upload the geotiffs to the bucket using the google command line tool)
4.	04_bucket_to_gee_asset.ipynb
5.	05_calc_era5land_climate_params.ipynb


1.	Downloads ERA5 data from the Climate Data Store API for the specified parameter, year and month, area, and saves them locally.  
Output – .nc files with the naming convention ‘era5_{parameter}_{hourly/monthly}_{year}_{month}.nc’
The total precipitation is downloaded on the monthly time step, but the temperature rasters are downloaded on an hourly timestep, because there is no monthly min/max temperature ERA5 data available in Climate Data Store, and the monthly rasters in GEE are calculated based on the hourly data.

2.	The script creates a monthly timestep geotiff from the ERA5 netcdf files and saves it locally. 
Input – netcdf files (one for each parameter, month and year) for the selected years (2020-2023).
Output – a geotiff for each parameter and each month of each year. Naming convention: {region}_era5_{parameter}_monthly_{year}_{month}.tif.
Additional steps in the script:
a. From the 2m temperature hourly .ncs, a mean, min, and max rasters of the month are created (to align the method to ERA5Land monthly rasters that are calculated from hourly data).  
b. As ERA5 monthly averaged data has units m per day in the month, and total precipitation is needed, values of each timeslice are multiplied by the number of days of that month.	 
c. The transform from the netcdf is used and crs (WGS 84, EPSG: 4326) is assigned because the netcdf files don’t contain crs information. 
d. The parameter names differ between GEE and Copernicus Data Store (e.g., ‘mean_2m_air_temperature’ in GEE and ‘t2m’ in Copernicus Data Store), so the parameter names are overwritten according to GEE.

3.	Use command ‘ gcloud storage cp -r /local/path/to/geotiffs/folder/era5_monthly_rasters_2020_2023  gs://isaac_shared/{region}_nodata’. 
The sub-folders are created on the fly, the parameter ‘-r’ means recursion, where the folder and all its contents are uploaded. The same local folder name will be used in the bucket.
4.	Uploads all files (geotiffs) from a folder in the google bucket to GEE as assets using the earthengine command line tool.
Input: .json bucket access key,  GEE authentication, folder path to the geotiffs in the Google Cloud, path to the folder for the GEE assets.
Output: geotiffs as assets in GEE private project asset folder.
a.	Optionally deletes the existing folder and files in it for re-runs, since it does not automatically overwrite the files.
5.	Creates the yearly mean 2 m temperature and yearly precipitation sum rasters for years 2017-2023 by overlaying ERA5 (lower resolution) and ERA5 Land (higher resolution) so that ERA5 Land covers the land area and where there is no ERA5 Land cell, ERA5 is used. Exports 30m/90m raster tiles covering the Baltics/Europe from the overlay.
Input: ERA5 Land, ERA5 image collections from GEE and Climate Data Store, regional information from the utils.py script functions.
Output: 10 tiles with 10 000 x 10 000 cells each for the extent of Baltic catchments in Baltic TM (EPSG: 25884) in 30 m resolution or European catchments in EPSG: 3035 in 90 m resolution.
a.	Tiles are 10 000 x 10 000 cells, because that is the maximum output image size in GEE.
b.	For the years 2020-2023, ERA5 image collection of each parameter is created from the private project assets.
c.	 For the temperature parameters, the mean of the image collection for the specific year is created. For precipitation, it is the sum.
d.	There are functions to visualize the in-between rasters and to export them to a private drive folder.
e.	The ERA5 and ERA5 Land rasters for the specific year are overlaid using the function ‘era5.blend(era5land)’ (so that ERA5 Land is on the top of ERA5). 
f.	Before the overlay, the ERA5 raster is resampled to the resolution of ERA5 Land using era5.reproject({era5land projection}, {era5land transform}) to use the Nearest Neighbor resampling.
g.	A test is performed to assess the overlay. First, an ‘overlay - ERA5’  raster is created, where the sea cells should be 0, but land cells should have random small values. Next, an ‘overlay – ERA5 Land’  raster is created, where the sea cells are NaN, and the land cells are 0. The function can be uncommented to see these test rasters.
h.	The original units of ERA5 and ERA5 Land are degrees in K and m per month (in GEE) or m per day in a month (in Climate Data Store). The units of the parameters in the script are recalculated to °Celsius for the temperature rasters and mm/ year for the precipitation rasters.
i.	Tiles which overlap with the base grid (specified in utils.py) are exported to the bucket. 
