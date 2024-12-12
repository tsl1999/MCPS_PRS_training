#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="external-rsid"
#SBATCH  -p short
#SBATCH --mem-per-cpu=70GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/update_rsid_external_GWAS.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx


module load R/4.2.1-foss-2022a
# 
# 
# Rscript $script_dir/0.3.update_rsid_external_gwas.R 37 \
# BBJCAD_2020_ucsc_meta-analysis_input 1 2 marker_no_allele



# Rscript $script_dir/0.3.update_rsid_external_gwas.R 37 \
# CC4D_UKB_meta_analysis1 1 2 MarkerName
# 
# Rscript $script_dir/0.3.update_rsid_external_gwas.R 38 \
# CKB_IHD_meta-analysis_input 2 3  meta-input #marker_no_allele
# 
# Rscript $script_dir/0.3.update_rsid_external_gwas.R 38 \
# BBJ_CKB_meta_analysis1 1 2  #meta MarkerName

