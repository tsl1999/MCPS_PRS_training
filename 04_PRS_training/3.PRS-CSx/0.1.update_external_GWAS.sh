#!/bin/bash

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources

# for BBJCAD
awk '{ print $22 " " $4 " " $3 " " $6 " " $7}' \
$gwas_external_dir/BBJCAD_2020_ucsc_meta-analysis_input.txt | sed   -e \
'1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' \
-e '1s/beta/BETA/' -e '1s/se/SE/'  > $gwas_external_dir/BBJCAD_2020_prscsx.txt 

#ukb
awk '{ print $26 " " $4 " " $5 " " $6 " " $7}' \
$gwas_external_dir/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt | sed   -e \
'1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' \
-e '1s/beta/BETA/' -e '1s/se/SE/'  > $gwas_external_dir/CAD_UKBIOBANK_prscsx.txt 


#CC4D
awk '{ print $27 " " $4 " " $5 " " $9 " " $10}' \
$gwas_external_dir/cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt | sed   -e \
'1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' \
-e '1s/beta/BETA/' -e '1s/se/SE/'  > $gwas_external_dir/cc4d_1KG_additive_2015_prscsx.txt 




