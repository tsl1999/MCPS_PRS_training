#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J ldpred
#SBATCH  -p short
#SBATCH --mem=60G
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/running_ldpred.out

module load R/4.2.1-foss-2022a

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/Testing_data/bfiles
script_dir=$CURDIR/04_PRS_training/2.LDPred
gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis
output_dir=$CURDIR/Testing_data/PRS
log_dir=$CURDIR/06_testing/out/LDPred_h2"$1"_p"$2"_"$gwas".log

maf=0.001
h2="$1"
p="$2",1
gwas="$3"
 Rscript $script_dir/0.4.run_LDPred2.R \
$gwas_dir $genotype_files $output_dir \
 "$log_dir"  metal_$gwas $maf $p $h2
 