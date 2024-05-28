#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="prsice"
#SBATCH  -p long
#SBATCH --mem-per-cpu=50GB
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=1
#SBATCH --array=1-10
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/1.P+T/out/prsice_fold%a.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_DIR=$CURDIR/04_PRS_training/1.P+T
input_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/meta-analysis
module purge
module load R/4.2.1-foss-2022a
for gwas in ukb_ckb ukb_ckb_cc4d_bbj ; do
 for r2 in 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 ; do
   srun --ntasks=1 --nodes=1 --cpus-per-task=1 bash $script_DIR/0.3.setup_PRSice2.sh \
   $SLURM_ARRAY_TASK_ID metal_$gwas $r2 &
   
done
done 
wait

#ukb_cc4d ukb_cc4d_bbj cc4d_bbj
#0.3 0.4 0.5 0.6 0.7 0.8 0.9