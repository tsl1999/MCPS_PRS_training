#!/bin/bash


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
mcps_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_"$1"
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis

module purge
module load R/4.2.1-foss-2022a 

echo prepare metal script

Rscript $SCRIPT_DIR/3.0.3.prep_metal_script.R  $SCRIPT_DIR  $mcps_gwas "$2" "$1" "$3" 


echo run metal
$METAL_DIR/metal  $SCRIPT_DIR/run_metal/"$1"/metal_"$3"_"$1".txt

echo done