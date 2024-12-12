#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p long
#SBATCH --mem-per-cpu=35GB
#SBATCH --cpus-per-task=2
#SBATCH --array=1-10
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/1.P+T/out/fold%a/prsice_%x.out

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_DIR=$CURDIR/04_PRS_training/1.P+T
input_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/meta-analysis
module purge
#module load R/4.2.1-foss-2022a
#module load R/4.3.2-gfbf-2023a
 
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1
srun --ntasks=1 --nodes=1 --cpus-per-task=2 --cpu-bind=none  bash $script_DIR/0.3.setup_PRSice2.sh \
   $SLURM_ARRAY_TASK_ID "$1" "$2" 
   


#ukb_cc4d ukb_cc4d_bbj cc4d_bbj
#0.3 0.4 0.5 0.6 0.7 0.8 0.9
