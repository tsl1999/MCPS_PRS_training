#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="chr-rsid"
#SBATCH  -p short
#SBATCH --mem-per-cpu=100GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/out/rsid_chr.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training

module load R/4.2.1-foss-2022a
Rscript $script_dir/0.1.rsid_chr_pos.R
