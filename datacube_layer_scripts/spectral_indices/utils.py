import ee
import rasterio
import geopandas as gpd
from rasterio.transform import from_origin
from rasterio.features import rasterize, sieve


# Get bounding geometry for region
def get_wgs84_region_bounds(short_region_name):
    if short_region_name == "est":
        coords = [[[21.663979085384977, 57.47117120009354],
                   [28.27558936118248, 57.47117120009354],
                   [28.27558936118248, 59.85174961411087],
                   [21.663979085384977, 59.85174961411087],
                   [21.663979085384977, 57.47117120009354]]]
    elif short_region_name == "bal":
        coords = [[[20.409802201682762, 51.55365723878371],
                   [36.40692294136933, 51.55365723878371],
                   [36.40692294136933, 60.07724582840343],
                   [20.409802201682762, 60.07724582840343],
                   [20.409802201682762, 51.55365723878371]]]
    elif short_region_name == "eur":
        coords = [[[-31.418679048707954, 29.93535649098759],
                   [70.7949995368037, 29.93535649098759],
                   [70.7949995368037, 71.96326217021307],
                   [-31.418679048707954, 71.96326217021307],
                   [-31.418679048707954, 29.93535649098759]]]
    return ee.Geometry.Polygon(
        coords, proj=ee.Projection("EPSG:4326"), geodesic=False
    )


# Get pixel size based on region name
def get_region_pixel_size(short_region_name):
    if short_region_name == "est":
        return 10
    elif short_region_name == "bal":
        return 30
    elif short_region_name == "eur":
        return 90
    

# Add ID to grid tile
def add_tile_id(grid_tiles, index):
    index = ee.Number(index)
    tile = ee.Feature(
        grid_tiles.toList(grid_tiles.size()).get(index.subtract(1))
    )
    tile_id = ee.String(index.format("%02d"))
    return tile.set({"tile_id": tile_id})


# Create GEE grid tiles
def gee_grid_tiles(bounds, proj, pixel_size, tile_cells=10000):
    
    # Generate grid tiles
    scale = pixel_size * tile_cells
    grid_tiles = (
        bounds
        .transform(ee.Projection(proj), maxError=1)
        .coveringGrid(proj=proj, scale=scale)
    )
    
    # Add tile IDs to grid tiles
    tile_count = grid_tiles.size()
    tile_indices = ee.List.sequence(1, tile_count)
    grid_tiles_with_ids = ee.FeatureCollection(
        tile_indices.map(lambda index: add_tile_id(grid_tiles, index))
    )
    
    return grid_tiles_with_ids


# Get CRS based on region name
def get_region_crs(short_region_name):
    if short_region_name == "est":
        return "EPSG:3301"
    elif short_region_name == "bal":
        return "EPSG:25884"
    elif short_region_name == "eur":
        return "EPSG:3035"


# Get transform based on bounds and pixel size
def get_region_transform(short_region_name):

    # Get pixel size
    pixel_size = get_region_pixel_size(short_region_name)

    if short_region_name == "est":

        # gs://geo-assets/grid_tiles/referentsvorgustik.tif
        return [pixel_size, 0, 369000, 0, -pixel_size, 6635000]
    
    elif short_region_name == "bal":

        # gs://geo-assets/grid_tiles/bal_catchments_raster_25884.tif
        return [pixel_size, 0, 300000, 0, -pixel_size, 6660000]
    
    elif short_region_name == "eur":

        # gs://geo-assets/grid_tiles/eur_ref_grid.tif
        return [pixel_size, 0, 2635920, 0, -pixel_size, 5415750]


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


# Create reference raster grid
def create_ref_raster_grid(
        input_data, bounds, pixel_size, out_fp, sieve_size=2
    ):
    
    # Read reference vector data
    if isinstance(input_data, str):
        gdf = gpd.read_file(input_data)
    elif isinstance(input_data, gpd.GeoDataFrame):
        gdf = input_data

    # Define raster parameters
    xmin, ymin, xmax, ymax = bounds
    width = int((xmax - xmin) / pixel_size)
    height = int((ymax - ymin) / pixel_size)
    transform = from_origin(xmin, ymax, pixel_size, pixel_size)
    
    # Burn geometries into a binary raster
    out_raster = rasterize(
        [(geom, 1) for geom in gdf.geometry],
        out_shape=(height, width),
        transform=transform,
        fill=0,
        all_touched=False,
        dtype="uint8"
    )

    # Remove small raster polygons
    out_raster_sieved = sieve(out_raster, size=sieve_size)
    
    # Write to raster
    with rasterio.open(
        out_fp,
        "w",
        driver="GTiff",
        height=height,
        width=width,
        count=1,
        dtype="uint8",
        crs=gdf.crs,
        transform=transform,
        nodata=0,
        compress="lzw",
        predictor=2
    ) as dst:
        dst.write(out_raster_sieved, 1)


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
    elif short_ds_name == "lsat":
        return "landsat"
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
    

# Get nodata value based on variable
def get_nodata_value(variable, short_region_name=None):
    if variable in ["wiw", "strahler_order"]:
        return 255
    elif (
        (
            variable in ["vvvhr", "cti", "flow_acc"]
        ) and (
            short_region_name == "eur"
        )
    ):
        return -99999
    else:
        return -9999
