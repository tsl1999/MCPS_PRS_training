#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="duplicated save"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH --ntasks=10
#SBATCH -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/check_lifted.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
SCRIPTDIR=$CURDIR/03_GWAS/03_meta-analysis

module purge
module load R/4.2.1-foss-2022a
Rscript $SCRIPTDIR/3.1.3.check_lifted.R