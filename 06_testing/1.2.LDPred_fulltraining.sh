#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J ldpred
#SBATCH  -p short
#SBATCH --mem=250G
#SBATCH  -c 20
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/running_ldpred.out

module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/Testing_data/bfiles
script_dir=$CURDIR/06_testing
gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis
output_dir=$CURDIR/Testing_data/PRS/2.LDPred
log_dir=$CURDIR/06_testing/out/LDPred.log
mkdir $CURDIR/Testing_data/PRS/2.LDPred

maf=0.001
h2=0.02,0.04,0.05
p=0.23,0.38,0.53
gwas=his_ukb_ckb_cc4d_bbj
 Rscript $script_dir/0.5.run_LDPred2.R \
$gwas_dir $genotype_files $output_dir \
 "$log_dir"  metal_$gwas $maf $p $h2 norm
 