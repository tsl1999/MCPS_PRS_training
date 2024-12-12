#!/bin/bash



CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_DIR=$CURDIR/04_PRS_training/1.P+T
module purge
#module load R/4.2.1-foss-2022a
#module load R/4.3.2-gfbf-2023a
 
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1

#ukb_cc4d ukb_cc4d_bbj cc4d_bbj ukb_ckb ukb_ckb_cc4d_bbj his_ukb_cc4d his_all his_ukb_ckb_cc4d_bbj
#ukb_cc4d ukb_cc4d_bbj cc4d_bbj ukb_ckb ukb_ckb_cc4d_bbj his_ukb_cc4d his_all his_ukb_ckb_cc4d_bbj his_ukb_cc4d_bbj
for gwas in   his_ukb_cc4d his_all his_ukb_ckb_cc4d_bbj his_ukb_cc4d_bbj   ; do
 for r2 in 0.2 0.3 0.4 0.5 0.6 0.7 0.8  0.9  1  ; do
   sbatch --job-name=prsice_"$gwas"_"$r2" $script_DIR/1.1.run_PRSice2_cv.sh metal_$gwas $r2
done
done 
#0.85 0.95

#ukb_cc4d ukb_cc4d_bbj cc4d_bbj
#0.3 0.4 0.5 0.6 0.7 0.8 0.9
# 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1
