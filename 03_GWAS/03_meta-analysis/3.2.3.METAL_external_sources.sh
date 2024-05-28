#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="metal-external"
#SBATCH  -p short
#SBATCH --mem=30GB
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/metal_external.out




CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis

module purge
module load R/4.2.1-foss-2022a 
echo run metal
#$METAL_DIR/metal  $SCRIPT_DIR/run_metal/metal_ukb_cc4d_european.txt

$METAL_DIR/metal  $SCRIPT_DIR/run_metal/metal_bbj_ckb_asian.txt

echo done