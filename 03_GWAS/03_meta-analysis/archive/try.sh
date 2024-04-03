#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="try"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/try.out
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
EXTERNAL_GWAS=$CURDIR/external_data/GWAS_sources
mcps_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis

temparg=/well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_regenie/gwas_regenie_CAD_EPA_80

module purge
module load R/4.2.1-foss-2022a 



echo prepare metal script
Rscript $SCRIPT_DIR/3.0.2.prep_meta-analysis.R $SCRIPT_DIR  $temparg \
$EXTERNAL_GWAS/CAD_UKBIOBANK_METAL_input.txt,$EXTERNAL_GWAS/cc4d_1KG_additive_2015_METAL_input.txt \
fulltraining ukb_cc4d 1
# 
# echo run metal
# module purge
# module load Metal/2011-03-25-foss-2016a
# #$METAL_DIR/metal 
# metal $SCRIPT_DIR/run_metal/fulltraining/metal_ukb_cc4d_fulltraining.txt
# 
# echo done