#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="rsid"
#SBATCH  -p short
#SBATCH --mem-per-cpu=70GB
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/update_rsid_mcps.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID

module load R/4.2.1-foss-2022a
Rscript $script_dir/0.1.update_rsid_mcps_gwas.R $mcps_gwas_dir
