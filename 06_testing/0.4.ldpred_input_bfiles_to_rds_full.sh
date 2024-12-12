#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="bfile-rds"
#SBATCH  -p short
#SBATCH --mem-per-cpu=80GB
#SBATCH --ntasks=23
#SBATCH --cpus-per-task=1
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/bfiles-rds.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/Testing_data/bfiles
script_dir=$CURDIR/04_PRS_training/2.LDPred
#module load R/4.2.1-foss-2022a
module load R/4.3.2-gfbf-2023a

for chr in  $(seq 1 22) X;do
srun --ntasks=1 --nodes=1 --cpus-per-task=1 Rscript $script_dir/0.3.input_bfiles_to_rds.R \
$genotype_files $chr &
done
wait