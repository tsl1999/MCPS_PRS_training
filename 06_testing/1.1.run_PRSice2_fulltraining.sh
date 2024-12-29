#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="prsice"
#SBATCH  -p long
#SBATCH --mem=20GB
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/prsice_full.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
prsice_DIR=$CURDIR/Software/PRSice
input_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis

genotype_files=$CURDIR/Testing_data/bfiles
mkdir $CURDIR/Testing_data/PRS
mkdir $CURDIR/Testing_data/PRS/1.P+T
output_DIR=$CURDIR/Testing_data/PRS/1.P+T
mkdir $output_DIR/"$1"


#need gwas name, r2 and p-value

module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1


Rscript $prsice_DIR/PRSice.R --dir . \
    --prsice $prsice_DIR/PRSice_linux \
    --base  $input_gwas/"$1"1.txt \
    --target $genotype_files/mcps-subset-chr# \
    --keep $CURDIR/Testing_data/pheno_testing_CAD_EPA_80.txt \
    --exclude $CURDIR/data/bfiles/snp_to_exclude.txt \
    --thread 1 \
    --clump-r2 "$2" \
    --clump-kb 250 \
    --beta \
    --snp MarkerName --chr Chromosome --bp Position --A1 Allele1 --A2 Allele2 --stat Effect  --pvalue P-value \
    --ignore-fid T \
    --binary-target T \
    --seed 1000 \
    --no-regress \
    --score sum \
    --bar-levels "$3" \
    --all-score \
    --fastscore \
    --print-snp \
    --out $output_DIR/"$1"/"$2"

#p-value will start from 0.5 with interval of 5e-5