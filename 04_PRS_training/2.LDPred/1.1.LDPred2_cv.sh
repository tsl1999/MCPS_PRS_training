#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J ldpred
#SBATCH  -p short
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=17
#SBATCH --ntasks=6
#SBATCH --array=1-10
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred/out/fold%a/running_ldpred.out

module load R/4.2.1-foss-2022a


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/fold$SLURM_ARRAY_TASK_ID
script_dir=$CURDIR/04_PRS_training/2.LDPred
gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/meta-analysis
output_dir=$CURDIR/Training_data/PRS/2.LDPred/fold$SLURM_ARRAY_TASK_ID
log_dir=$script_dir/out/fold$SLURM_ARRAY_TASK_ID

maf=0.05
h2=0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.4
p=1e-10,100

for gwas in ukb_cc4d ukb_cc4d_bbj cc4d_bbj ; do
 srun --ntasks=1 --cpus-per-task=$SLURM_CPUS_PER_TASK Rscript $script_dir/0.4.run_LDPred2.R \
$gwas_dir $genotype_files $output_dir \
 "$log_dir"/LDpred_"$gwas".log  metal_$gwas $maf $p $h2&
 done 
 wait
 

#









