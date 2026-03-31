# Installing required R packages on HPC

The easiest way to install the required R packages on the HPC system is to use micromamba to create a dedicated R environment.

```bash
micromamba create -n spectraldiv
```

Activate the environment and install the R packages that are available in the conda repositories.

```bash
micromamba activate spectraldiv
micromamba install -c conda-forge r-base=4.4 r-terra r-future r-future.apply r-progressr r-devtools r-parallelly
```

The packages `spinR`, `preprocS2` and the newest version of `biodivMapR` are not available through conda and need to be installed from GitHub within an R session.

Launch R from the activated micromamba environment.

```bash
R
```

Then run the following commands in the R console.

```R
devtools::install_github('jbferet/preprocS2')
devtools::install_gitlab('jbferet/spinR')
devtools::install_github('jbferet/biodivMapR@dev_v2')
```

# Input data preparation

The package `biodivMapR` calculates spectral diversity based on moving windows. The package skips diversity calculation near input image boundaries as moving windows in those areas are only partially filled with pixels. Script `prepare_div_calc_input_hpc.sh` pads input tiles (10000 by 10000 px) by 10% (1000 px) to avoid missing pixels near tile boundaries.

```bash
# Generate padded S2 tiles from June to August 2025
sbatch prepare_div_calc_input_hpc.sh 2025-06-01 2025-08-31
```

# Running the spectral diversity calculation on HPC

You can now run the `calc_diversity_hpc.sh` script on the HPC system using `sbatch`. The script will automatically activate the micromamba environment before running the R script. It takes the start and end dates of the given season as command line arguments along with the tile ID.

```bash
# Calculate spectral diversity for tile 09 from June to August 2025
sbatch calc_diversity_hpc.sh 2025-06-01 2025-08-31 09
```

For launching the processing jobs for multiple tiles, you can use a loop in your shell.

```bash
# Launch processing jobs for all 14 Estonian tiles
for T in 04 05 06 07 08 09 10 11 12 13 14 15 18 19; do sbatch calc_diversity_hpc.sh 2025-06-01 2025-08-31 $T; done
```

# Preparing spectral tiles for bucket export

Script `prepare_bucket_tiles.sh` converts the initial padded spectral diversity calculation outputs into a suitable format for the Google bucket export. The padded tiles are clipped to bucket tile boundaries and converted to Int16 to reduce storage needs.

```bash
# Prepare spectral diversity tiles from June to August 2025 for bucket export
sbatch prepare_bucket_tiles.sh 2025-06-01 2025-08-31 IN_DIR
```