#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p himem
#SBATCH --mem=450GB
#SBATCH  -c 20
#SBATCH --array=1-10
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred/out/fold%a/running_ldpred_%x.out

#module load R/4.2.1-foss-2022a
#module load R/4.3.2-gfbf-2023a 
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/fold$SLURM_ARRAY_TASK_ID
script_dir=$CURDIR/04_PRS_training/2.LDPred
gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/meta-analysis
output_dir=$CURDIR/Training_data/PRS/2.LDPred/fold$SLURM_ARRAY_TASK_ID
log_dir=$script_dir/out/fold$SLURM_ARRAY_TASK_ID

maf="$1" #0.001
#h2=$(seq 0.01 0.01 0.2|awk '{printf "%s%s",sep,$0; sep=","} END{print ""}') #0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.4
h2="$2" #$h2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0
p="$3" #1e-10,100
gwas="$4"

#for gwas in ukb_cc4d ukb_cc4d_bbj cc4d_bbj ukb_ckb ukb_ckb_cc4d_bbj 
 srun  Rscript $script_dir/0.4.run_LDPred2.R \
$gwas_dir $genotype_files $output_dir \
 "$log_dir"/LDpred_"$gwas"_new.log  metal_$gwas $maf $p $h2

 

#ukb_cc4d ukb_cc4d_bbj cc4d_bbj









