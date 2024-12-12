#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="logistic_comparison"
#SBATCH  -p short
#SBATCH --mem=30gb
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/out/logistic_comparison.out


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/05_CAD_analysis_cv
#module load R/4.2.1-foss-2022a
module load R/4.3.2-gfbf-2023a
Rscript $script_dir/2.1.10_fold_comparison_P+T.R
Rscript $script_dir/2.1.10_fold_comparison_LDPred.R
Rscript $script_dir/2.1.10_fold_comparison_PRS-CSx.R