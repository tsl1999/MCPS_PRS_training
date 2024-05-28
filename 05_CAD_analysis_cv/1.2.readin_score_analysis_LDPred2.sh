#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="ldpred2_logistic"
#SBATCH  -p short
#SBATCH --mem=30gb
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/out/fold%a/ldpred2_logistic.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
validation_file_path=$CURDIR/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID
script_dir=$CURDIR/05_CAD_analysis_cv
PT_results_path=$CURDIR/Training_data/PRS/2.LDPred/fold$SLURM_ARRAY_TASK_ID
module purge
module load R/4.2.1-foss-2022a

for gwas in cc4d_bbj ukb_cc4d ukb_cc4d_bbj; do
Rscript $script_dir/1.2.readin_score_analysis_LDPred2.R $PT_results_path/metal_$gwas $validation_file_path
done
