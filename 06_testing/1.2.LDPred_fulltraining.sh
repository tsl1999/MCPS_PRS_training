#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J ldpred
#SBATCH  -p short
#SBATCH --mem=250G
#SBATCH  -c 20
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tianshu.liu@stx.ox.ac.uk
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/running_ldpred.out

module load R/4.3.2-gfbf-2023a

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/Testing_data/bfiles
script_dir=$CURDIR/06_testing
gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis
output_dir=$CURDIR/Testing_data/PRS/2.LDPred
log_dir=$CURDIR/06_testing/out/LDPred.log
mkdir $CURDIR/Testing_data/PRS/2.LDPred

maf=0.001
h2=0.025
p=0.0505,0.051,0.050
gwas=ukb_ckb_cc4d_bbj
 Rscript $script_dir/0.5.run_LDPred2.R \
$gwas_dir $genotype_files $output_dir \
 "$log_dir"  metal_$gwas $maf $p $h2 meta-analysis
 