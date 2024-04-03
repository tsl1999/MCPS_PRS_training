#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="update_bfiles"
#SBATCH  -p short
#SBATCH --mem-per-cpu=50GB
#SBATCH --ntasks=23
#SBATCH --cpus-per-task=1
#SBATCH --array=1-10
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred/out/fold%a/update_bfiles.out

##later when stramline the process this file should be in 1.PRSice as now P+T also uses subset bfiles now

module load PLINK/2.00a3.1-GCC-11.2.0


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles
validation_path=$CURDIR/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID
mkdir $genotype_files/fold$SLURM_ARRAY_TASK_ID

for chr in $(seq 1 22) X; do

srun --ntasks=1 --nodes=1 --cpus-per-task=1 plink2 --bfile $genotype_files/mcps-freeze150k_qcd_chr$chr \
--keep $validation_path/validation_data.txt --make-bed \
--out $genotype_files/fold$SLURM_ARRAY_TASK_ID/mcps-subset-chr$chr &

done
wait

