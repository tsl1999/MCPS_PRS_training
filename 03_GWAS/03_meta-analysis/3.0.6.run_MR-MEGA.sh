#!/bin/bash

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
mcps_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_"$1"
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis
MEGA_DIR=$CURDIR/Software/MR-MEGA
module purge
module load R/4.2.1-foss-2022a 

echo prepare mr-mega script

Rscript $SCRIPT_DIR/3.0.5.prep_mr-mega_script.R  $SCRIPT_DIR  $mcps_gwas \
"$2" "$1" "$3" 

module purge
module load Python/3.10.8-GCCcore-12.2.0

$MEGA_DIR/MR-MEGA \
  -i $SCRIPT_DIR/run_MR-MEGA/"$1"/mr-mega_"$3"_"$1".in \
  --name_pos  position\
  --name_chr chr \
  --name_n N \
  --name_or OR \
  --name_or_95u OR_95U\
  --name_or_95l OR_95L\
  --name_se se \
  --name_eaf effect_allele_freq \
  --name_nea non_effect_allele \
  --name_ea effect_allele \
  --name_marker marker_no_allele\
  --no_std_names \
  -o $mcps_gwas/meta-analysis/mr-mega_"$3"


