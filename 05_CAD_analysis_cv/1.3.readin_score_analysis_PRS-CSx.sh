#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="prscsx_logistic"
#SBATCH  -p short
#SBATCH --mem=30gb
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/out/fold%a/prscsx_logistic.out


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
validation_file_path=$CURDIR/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID
script_dir=$CURDIR/05_CAD_analysis_cv
PT_results_path=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
# module load R/4.2.1-foss-2022a
module load R/4.3.2-gfbf-2023a

mcps_bbj_pop=AMR,EAS,META
mcps_ukb_pop=AMR,EUR,META
mcps_bbj_ukb_pop=AMR,EAS,EUR,META
mcps_bbj_eur_pop=AMR,EAS,EUR,META
mcps_ukb_ckb_pop=AMR,EUR,EAS,META
mcps_eur_eas_pop=AMR,EUR,EAS,META
his_eur_eas_pop=AMR,EUR,EAS,META
his_eur_pop=AMR,EUR,META




Rscript $script_dir/1.3.readin_score_analysis_PRS-CSx.R $mcps_bbj_pop:$mcps_ukb_pop:$mcps_bbj_ukb_pop:$mcps_bbj_eur_pop:$mcps_ukb_ckb_pop:$mcps_eur_eas_pop:$his_eur_pop:$his_eur_eas_pop \
mcps_bbj,mcps_ukb,mcps_bbj_ukb,mcps_bbj_eur,mcps_ukb_ckb,mcps_eur_eas,his_eur,his_eur_eas 1e-07,1e-06,1e-05,1e-04,1e-02,1,auto $PT_results_path $validation_file_path

#