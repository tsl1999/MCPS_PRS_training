#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="liftover"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/liftover_ensemble.out

#liftover via ensemble chain
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
SCRIPTDIR=$CURDIR/03_GWAS/03_meta-analysis
DATA_DIR=$CURDIR/external_data/GWAS_sources

module purge
module load CrossMap/0.6.1-foss-2021a-Python-3.9.5
module load R/4.2.1-foss-2022a
cd $DATA_DIR
#CrossMap.py -h
#CrossMap.py bed GRCh37_to_GRCh38.chain.gz  cc4d_1KG_additive_2015.bed cc4d_lifted_test.bed


#all three GWAS sources used hg19 genome build, which need to be lifted over to hg38 (GRCH38)
run_liftover () {
  local gwas=$1

CrossMap.py bed  $CURDIR/external_data/GRCh37_to_GRCh38.chain.gz \
$DATA_DIR/"$gwas".bed  $DATA_DIR/"$gwas"_liftedhg38_ensemble.bed

wc $DATA_DIR/"$gwas"_liftedhg38_ensemble.bed.map


echo running step 2 R
Rscript $SCRIPTDIR/3.0.1.liftover.R step2 \
$DATA_DIR $gwas ensemble
}


for gwas in cc4d_1KG_additive_2015 BBJCAD_2020 CAD_UKBIOBANK;
 do run_liftover "$gwas"&
done
wait