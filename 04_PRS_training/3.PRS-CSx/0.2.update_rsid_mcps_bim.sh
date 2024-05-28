#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="bim-rsid"
#SBATCH  -p short
#SBATCH --mem-per-cpu=60GB
#SBATCH --array=1-22
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/update_rsid_bim.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
mcps_bim_dir=$CURDIR/data/bfiles

module load R/4.2.1-foss-2022a
Rscript $script_dir/0.2.update_rsid_mcps_bim.R $mcps_bim_dir $SLURM_ARRAY_TASK_ID
