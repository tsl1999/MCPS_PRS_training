#!/bin/bash
#SBATCH --job-name="qc-cv"
#SBATCH --mem-per-cpu=100G
#SBATCH --ntask=10
#SBATCH --cpus-per-task=1
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/01_qc_variants/out/qc_variant_CAD_EPA_80_cv.out



for i in {1..10};
do 
cd /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/01_qc_variants
srun --ntasks=1 -nodes=1 --cpus-per-task=1 bash 01.qc_variants_cv.sh "$i" &
done
wait



