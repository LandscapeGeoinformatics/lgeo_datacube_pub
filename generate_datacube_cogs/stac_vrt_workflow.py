import argparse
from typing import List, Optional

import pystac_client
from osgeo import gdal


def get_stac_assets(
    stac_api_url: str,
    collection_id: str = "bucket_name-estonia-sentinel2-ndvi-2024",
    asset_key: str = "gsdata",
) -> List[str]:
    """
    Query a STAC API endpoint and retrieve cloud storage URLs for GeoTIFF assets

    Parameters:
    -----------
    stac_api_url : str
        The STAC API endpoint URL
    collection_id : str
        The collection ID to query
    asset_key : str
        The asset key containing the GeoTIFF URL

    Returns:
    --------
    List[str]
        List of cloud storage URLs for the GeoTIFF assets
    """
    # Initialize STAC client
    catalog = pystac_client.Client.open(stac_api_url)

    # Search the collection
    search = catalog.search(collections=[collection_id])
    items = search.get_all_items()

    # Extract asset URLs
    urls = []
    for item in items:
        if asset_key in item.assets:
            asset = item.assets[asset_key]
            if asset.media_type.startswith("image/tiff"):
                urls.append(asset.href)
                print(f'stac-assets+ {asset.href}')

    return urls


def filter_pattern(s_in: str, filter_contains: str) -> bool:
    return filter_contains in s_in


def map_gs_to_vsigs(url_in: str) -> str:
    return url_in.replace("gs://", "/vsigs/")


def create_vrt(
    geotiff_urls: List[str],
    output_vrt: str = "output.vrt",
    srs: Optional[str] = None
) -> str:
    """
    Create a GDAL VRT from a list of GeoTIFF URLs

    Parameters:
    -----------
    geotiff_urls : List[str]
        List of URLs to GeoTIFF files
    output_vrt : str
        Path to save the output VRT file
    srs : Optional[str]
        Target spatial reference system (e.g., 'EPSG:4326')

    Returns:
    --------
    str
        Path to the created VRT file
    """

    # Build VRT options
    vrt_options = gdal.BuildVRTOptions(
        # Each file becomes a separate band
        separate=False,
        srcNodata=None,
        outputSRS=srs,
    )
    print(vrt_options)

    # Create the VRT
    gdal.BuildVRT(output_vrt, geotiff_urls, options=vrt_options)

    return output_vrt


# Example usage
if __name__ == "__main__":
    # Configure your STAC endpoint
    STAC_API_URL = "https://maps.landscape-geoinformatics.org/stac"
    parser = argparse.ArgumentParser(
        description="Query a stac selection and create a VRT mosaic."
    )
    parser.add_argument("collection_id", help="the target stac colelction")
    parser.add_argument(
        "-o", "--outputfilename", help="the VRT output filename (optional)"
    )
    parser.add_argument(
        "-a", "--asset_key", help="the STAC asset key, our gsdata (optional)"
    )
    parser.add_argument(
        "-f",
        "--filtered_by",
        help="a fiter string e.g. for summer only _08-31 (optional)",
    )

    # Parse the arguments
    args = parser.parse_args()
    collection_id = args.collection_id
    vrt_out = collection_id + ".vrt"
    asset_key = "gsdata"
    filtered_by = None # "_08-31"

    if args.outputfilename:
        vrt_out = args.outputfilename

    if args.asset_key:
        asset_key = args.asset_key

    if args.filtered_by:
        filtered_by = args.filtered_by

    try:
        # Get the GeoTIFF URLs
        geotiff_urls = get_stac_assets(
            STAC_API_URL, collection_id=collection_id, asset_key=asset_key
        )
        print(f"Found {len(geotiff_urls)} GeoTIFF assets")

        new_urls = list(map(map_gs_to_vsigs, geotiff_urls))
        print(f'mapped_gs: {new_urls}')
        if filtered_by is not None:
            new_urls = list(filter(lambda u: filter_pattern(u, filtered_by), new_urls))
        
        print(f'filtered: {new_urls}')
        # Create the VRT
        vrt_path = create_vrt(
            new_urls,
            output_vrt=vrt_out,
            srs="EPSG:3301"  # Optional: reproject to WGS84
        )
        print(f"Created VRT at: {vrt_path}")

    except Exception as e:
        print(f"Error: {str(e)}")
