#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

# Set working directory to SLURM submission directory
root_dir <- Sys.getenv('SLURM_SUBMIT_DIR', unset = getwd())
setwd(root_dir)

library(biodivMapR)
library(preprocS2)
library(spinR)
library(sf)
library(future)
library(future.apply)
library(parallel)
library(progressr)
library(terra)

################################################################################
####             get Sentinel-2 data and compute spectral indices           ####
################################################################################
# 0- parameters for S2 download and processing
nbCPU <- as.integer(Sys.getenv('SLURM_CPUS_PER_TASK', unset = 8))
cellsize <- as.integer(args[1])

# Set up parallel processing
handlers(global = TRUE)

if (.Platform$OS.type == 'unix') {
  plan(multicore, workers = nbCPU)
} else {
  plan(multisession, workers = nbCPU)
}

# 0- parameters for biodivMapR and processing
window_size <- 5 #means that diversity metrics are computed for 5 pixels x 5 pixels (50 m x 50m) windows
options(fundiversity.memoise = FALSE)         # in case functional diversity computed
options <- list(moving_window = T,
                alpha_metrics = 'shannon',
                beta_metrics = FALSE,
                nb_samples_alpha = 100000,      # accurate Shannon - numeric. max number of pixels to extract for kmeans
                nb_iter = 2,                     # Reduce from 10 (5x faster) - nb of iterations averaged to compute diversity indices
                nb_clusters = 20,                # Reduce from 50 (2.5x faster) - number of clusters used in kmeans
                pcelim = 0.02,
                mosaic_output = TRUE)

start_date <- args[2]
end_date <- args[3]
siteName <- args[4]
input_dir <- file.path('./01_data', paste0(start_date, '_', end_date))
output_dir <- file.path('./03_results_unmasked', paste0(start_date, '_', end_date), siteName)
dir.create(path = output_dir, showWarnings = F, recursive = T)

# list files
img_path <- file.path(input_dir, paste0('est_s2_median_', start_date, '_', end_date, '_', siteName, '_pad.tif'))
img_rast <- terra::rast(img_path)

# Assign ALL 12 band names (including B01 and B09)
names(img_rast) <- c('B01', 'B02', 'B03', 'B04', 'B05', 'B06', 
                     'B07', 'B08', 'B8A', 'B09', 'B11', 'B12')
wl <- c(442.7, 492.7, 559.8, 664.6, 704.1, 740.5, 782.8, 832.8, 864.7, 945.1, 1613.7, 2202.4)

######### masking block
# produce mask
# ndvi <- (img_rast$B08-img_rast$B04)/(img_rast$B08+img_rast$B04)
# # mask NDVI values < 0.7
# mask_ndvi <- ndvi > 0.1
# mask_nir <- img_rast$B08 > 100
# mask_blue <- img_rast$B02 < 2500
# 
# # combine NDVI and NIR masks
# mask <- 0*img_rast$B02
# mask[mask_ndvi & mask_nir & mask_blue] <- 1
# names(mask) <- 'mask'
# 
# # save masks
# output_dir_mask <- file.path(output_dir, 'mask')
# dir.create(path = output_dir_mask, showWarnings = F, recursive = T)
# mask_path <- file.path(output_dir_mask, 
#                        paste0(basename(tools::file_path_sans_ext(img_path)), 
#                               '_mask.tiff'))
# terra::writeRaster(x = mask, filename = mask_path, overwrite = T)
##### END masking

img_ext <- get_raster_extent(img_rast)
aoi_path <- file.path(output_dir, 'aoi.gpkg')
terra::writeVector(x = img_ext, filename = aoi_path, overwrite = T)

# define tiling grid over peru
crs_target <- terra::crs(img_rast)
path_grid <- get_grid_aoi(aoi_path = aoi_path,
                          cellsize = cellsize,
                          output_dir = output_dir,
                          crs_target = crs_target)

crs_target <- path_grid$crs_target
plots <- path_grid$plots
nb_plots <- length(plots)
dsn_grid <- path_grid$dsn_grid

# compute mask and spectral indices for each plot
si_list <- c('LAI_SAVI', 'NDWI1', 'NDVI')
output_si <- compute_si_from_grid(rast_path = img_path, 
                                  mask_path = NULL, 
                                  plots = plots, 
                                  spectral_bands = wl, 
                                  siteName = siteName, 
                                  si_list = si_list, 
                                  output_dir = output_dir)

output_dir_si <- dirname(output_si[[1]][[1]])

mask_dir <- file.path(output_dir, 'SI_mask')
dir.create(path = mask_dir, showWarnings = F, recursive = T)

################################################################################
####                       pre-create dummy IQR masks                       ####
################################################################################

# create one all-valid mask per tile so biodivMapR skips IQR filtering
for (tile in names(plots)) {
  tag <- paste0('_', tile, '_')
  # grab any feature file from this tile (just to copy its shape/extent)
  f <- list.files(output_dir_si, pattern = tag, full.names = TRUE)[1]
  if (!is.na(f) && file.exists(f)) {
    r <- rast(f)
    m <- 1 + 0 * r[[1]]   # raster of all 1s (no NAs)
    writeRaster(
      m,
      file.path(mask_dir, sprintf('mask_%s_IQR.tiff', tile)),
      overwrite = TRUE
    )
  }
}

################################################################################
####                              run biodivMapR                            ####
################################################################################
message('initialization of biodivMapR')

# 1- define input & output directories
output_biodivMapR <- file.path(output_dir, paste0('biodivMapR_', paste(si_list, collapse = '_')))
dir.create(output_biodivMapR, showWarnings = F, recursive = T)
# mask_dir <- file.path(output_dir, 'SI_mask')
# dir.create(path = mask_dir, showWarnings = F, recursive = T)

# 2- apply biodivMapR to each tile
mosaic_path <- biodivMapR_full_tiles(feature_dir = output_dir_si, 
                                     list_features = si_list,
                                     mask_dir = mask_dir,
                                     output_dir = output_biodivMapR, 
                                     window_size = window_size, 
                                     plots = plots, 
                                     nbCPU = nbCPU,
                                     siteName = siteName, 
                                     options = options)
