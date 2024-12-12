#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="update_bfiles"
#SBATCH  -p short
#SBATCH --mem=50GB
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/update_bfiles.out

##later when stramline the process this file should be in 1.PRSice as now P+T also uses subset bfiles now

module load PLINK/2.00a2.3_x86_64

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles
#full training
validation_path=$CURDIR/Testing_data/pheno_testing_CAD_EPA_80.txt
mkdir $CURDIR/Testing_data/bfiles


for chr in $(seq 1 22) X; do

 plink2 --bfile $genotype_files/mcps-freeze150k_qcd_chr$chr \
--keep $validation_path --make-bed \
--out $CURDIR/Testing_data/bfiles/mcps-subset-chr$chr 

done
