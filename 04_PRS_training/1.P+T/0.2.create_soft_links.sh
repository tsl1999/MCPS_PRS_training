#!/bin/bash

cd genotype_files=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/imputation/oxford_qcd/per_chromosome/pgen_hds/bfiles/mcps-freeze150k_qcd_chr
data_file=/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles/mcps-freeze150k_qcd_chr
for i in $(seq 1 22) X;
do 
echo "$i"
ln -s $genotype_files"$i".bed  $data_file"$i".bed
ln -s $genotype_files"$i".fam  $data_file"$i".fam


done