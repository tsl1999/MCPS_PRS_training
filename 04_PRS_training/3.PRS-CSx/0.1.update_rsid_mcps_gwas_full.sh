#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="rsid-full"
#SBATCH  -p short
#SBATCH --mem-per-cpu=70GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fulltraining/update_rsid_mcps.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining

#module load R/4.2.1-foss-2022a
module load R-bundle-Bioconductor/3.18-foss-2023a-R-4.3.2
#Rscript $script_dir/0.1.update_rsid_mcps_gwas.R $mcps_gwas_dir data_mcps_meta-analysis_input_nodup.txt

Rscript $script_dir/0.1.update_rsid_mcps_gwas.R $mcps_gwas_dir/meta-analysis metal_his_all1.txt metal
