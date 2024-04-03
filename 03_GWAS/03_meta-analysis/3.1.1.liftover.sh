#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="liftover"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/liftover.out

# 1. updated gwas file, put chr in front of chromosome id and save, id each row so we can merge back
# 3. run liftover ./liftOver cc4d.bed hg19ToHg38.over.chain.gz output.bed unlifted.bed
# 4. remove the note line in unlifted and check number of rows in unlifted
# 5.grep -v "#Deleted in new" unlifted.bed >unlifted_up.bed
# wc unlifted_up.bed


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
SCRIPTDIR=$CURDIR/03_GWAS/03_meta-analysis
DATA_DIR=$CURDIR/external_data/GWAS_sources

cd $CURDIR

module purge
module load R/4.2.1-foss-2022a
#all three GWAS sources used hg19 genome build, which need to be lifted over to hg38 (GRCH38)
run_liftover () {
  local gwas=$1
  echo running step 1 R

col_id=$( grep -Po "^$gwas= \K.*" $SCRIPTDIR/col_ids.txt )
Rscript $SCRIPTDIR/3.0.1.liftover.R step1 \
$DATA_DIR  $gwas  $col_id

echo running liftover commandline
#chmod +x liftOver
#sed 's/\"//g' $CURDIR/cc4d.txt > $CURDIR/cc4d_new.txt
cut -f  1,2,3,4  $DATA_DIR/"$gwas"_updated.txt > $DATA_DIR/$gwas.bed

$CURDIR/Software/UCSC_liftover/liftOver $DATA_DIR/$gwas.bed $CURDIR/external_data/hg19ToHg38.over.chain.gz \
$DATA_DIR/"$gwas"_liftedhg38.bed $DATA_DIR/"$gwas"_unlifted.bed

grep -v "#Deleted in new" $DATA_DIR/"$gwas"_unlifted.bed > $DATA_DIR/"$gwas"_unlifted_up.bed
wc $DATA_DIR/"$gwas"_unlifted_up.bed

echo running step 2 R
Rscript $SCRIPTDIR/3.0.1.liftover.R step2 \
$DATA_DIR $gwas ucsc
}


for gwas in cc4d_1KG_additive_2015 BBJCAD_2020 CAD_UKBIOBANK;
 do run_liftover "$gwas"&
done
wait

echo done