#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="mr-mega"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/fultraining_mr-mega.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
EXTERNAL_GWAS=$CURDIR/external_data/GWAS_sources
mcps_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_fulltraining
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis

bash $SCRIPT_DIR/3.0.6.run_MR-MEGA.sh fulltraining \
$EXTERNAL_GWAS/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/BBJCAD_2020_ucsc_meta-analysis_input.txt \
ukb_cc4d


current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo metal analysis done