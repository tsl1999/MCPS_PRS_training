#!/bin/bash

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/fold"$1"
script_DIR=$CURDIR/04_PRS_training
input_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_"$1"/meta-analysis
prsice_DIR=$CURDIR/Software/PRSice
output_DIR=$CURDIR/Training_data/PRS/1.P+T

mkdir $output_DIR/fold"$1"
module load R/4.2.1-foss-2022a

input_levels=$(seq -s, 0.1 0.005 0.9)
mkdir $output_DIR/fold"$1"/"$2"
Rscript $prsice_DIR/PRSice.R --dir . \
    --prsice $prsice_DIR/PRSice_linux \
    --base  $input_gwas/"$2"1.txt \
    --target $genotype_files/mcps-subset-chr# \
    --keep $CURDIR/Training_data/crossfold/CAD_EPA/"$1"/validation_data.txt \
    --exclude $CURDIR/data/bfiles/snp_to_exclude.txt \
    --thread 1 \
    --clump-r2 "$3" \
    --clump-kb 250 \
    --beta \
    --snp MarkerName --chr Chromosome --bp Position --A1 Allele1 --A2 Allele2 --stat Effect  --pvalue P-value \
    --ignore-fid T \
    --binary-target T \
    --seed 1000 \
    --no-regress \
    --score sum \
    --bar-levels 5e-08,5e-07,5e-06,5e-05,5e-04,5e-03,5e-02,$input_levels \
    --all-score \
    --fastscore \
    --print-snp \
    --out $output_DIR/fold"$1"/"$2"/"$3"

#p-value will start from 0.5 with interval of 5e-5