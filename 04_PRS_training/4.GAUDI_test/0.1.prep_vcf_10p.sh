#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="update_vcf_tbi"
#SBATCH  -p short
#SBATCH --mem=30GB
#SBATCH --ntasks=22
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/4.GAUDI_test/out/update_vcf_tbi.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data

module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"
conda activate
conda activate vcf_tools_env
# 
for i in $(seq 2 1 22) X; do
#echo $i
#bcftools view -S $genotype_files/local_ancestry_rfmix/mcps_10p_iid.txt -o $genotype_files/vcf/mcps_subset_$i.vcf.gz -O z $genotype_files/vcf/mcps-freeze150k_qcd_chr$i.vcf.gz &
tabix -p vcf /well/emberson/users/hma817/projects/MCPS_PRS_training/data/vcf/mcps_subset_$i.vcf.gz &
done
wait


