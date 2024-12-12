#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="ldpred_submit"
#SBATCH  -p short
#SBATCH --mem=5GB
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred/out/ldpred_submit.out
#module load R/4.2.1-foss-2022a
module load R/4.3.2-gfbf-2023a 

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/2.LDPred


maf=0.001
h2=$(seq -s,  0.01 0.01 0.2)  #0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.4
#h2_more=$h2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0
p=$(seq -s, 0.01 0.01 1)
#ukb_cc4d_bbj cc4d_bbj ukb_ckb ukb_ckb_cc4d_bbj ukb_cc4d
for gwas in  his_ukb_cc4d his_all his_ukb_ckb_cc4d_bbj his_ukb_cc4d_bbj ; do
sbatch --job-name=ldpred_"$gwas" $script_dir/1.1.LDPred2_cv.sh $maf $h2 5e-10,5e-09,5e-08,5e-07,5e-06,5e-05,5e-04,5e-03,$p $gwas  

done

#ukb_cc4d_bbj cc4d_bbj ukb_ckb ukb_ckb_cc4d_bbj
