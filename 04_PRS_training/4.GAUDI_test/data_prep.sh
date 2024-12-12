#!/bin/bash

genotype_files=/well/emberson/users/pom143/Ancestry/local_ancestry/output_files/mcps_10p/RFMix/merged_output_
data_file=/well/emberson/users/hma817/projects/MCPS_PRS_training/data/local_ancestry_rfmix/merged_output_
for i in $(seq 1 22) X;
do 
echo "$i"
#ln -s $genotype_files"$i".msp.tsv  $data_file"$i".msp.tsv

gzip -c  $genotype_files"$i".msp.tsv >  $data_file"$i".msp.tsv.gz

done


genotype_files=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/imputation/oxford_qcd/per_chromosome/pgen_hds/vcf_dosages/mcps-freeze150k_qcd_chr
data_file=/well/emberson/users/hma817/projects/MCPS_PRS_training/data/vcf/mcps-freeze150k_qcd_chr
for i in $(seq 1 22) X;
do 
echo "$i"
ln -s $genotype_files"$i".vcf.gz  $data_file"$i".vcf.gz



done