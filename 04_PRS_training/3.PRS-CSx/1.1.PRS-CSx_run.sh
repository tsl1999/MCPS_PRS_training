#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p short
#SBATCH  -c 1
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/prscsx%x-submit.out


timestamp() {
  date "+%Y-%m-%d %H:%M:%S" # current time
}
timestamp

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/prscsx
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
software_dir=$CURDIR/Software/PRScsx
log_dir=$script_dir/out/fold$SLURM_ARRAY_TASK_ID
LDreference=$CURDIR/external_data/LD_reference
prs_result_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
bfiles=$CURDIR/data/bfiles/fold$SLURM_ARRAY_TASK_ID

module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1


mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID/$SLURM_JOB_NAME


phi="$1"



if [ -z "$5" ]; then

id=$(sbatch --parsable  --job-name=chrom-fold"$SLURM_ARRAY_TASK_ID"-$SLURM_JOB_NAME -o $script_dir/out/fold$SLURM_ARRAY_TASK_ID/prscsx$SLURM_JOB_NAME-chrom.out  \
$script_dir/1.0.1.set_up_PRS-CSx.sh \
$phi "$2" "$3" "$4" $SLURM_ARRAY_TASK_ID $SLURM_JOB_NAME)

echo Submitted batch job $id

else
echo amr is "$5"

id=$(sbatch --parsable  --job-name=chrom-fold"$SLURM_ARRAY_TASK_ID"-$SLURM_JOB_NAME -o $script_dir/out/fold$SLURM_ARRAY_TASK_ID/prscsx$SLURM_JOB_NAME-chrom.out  \
$script_dir/1.0.1.set_up_PRS-CSx.sh \
$phi "$2" "$3" "$4" $SLURM_ARRAY_TASK_ID $SLURM_JOB_NAME  "$5" "$6")

echo Submitted batch job $id

fi

gwas_phi=$SLURM_JOB_NAME
population=AMR,"$3",META

#

sbatch --dependency=afterok:$id --job-name=combine-fold"$SLURM_ARRAY_TASK_ID"-$SLURM_JOB_NAME -o $script_dir/out/fold$SLURM_ARRAY_TASK_ID/prscsx$SLURM_JOB_NAME-combine.out \
$script_dir/1.0.2.PRS-CSx_combine.sh $phi $gwas_phi $population $SLURM_ARRAY_TASK_ID




# var="${gwas}_pop"
# echo ${!var}
#  module load  R/4.2.1-foss-2022a
#  Rscript $script_dir/0.6.combine_prscsx_effect.R $prs_result_dir/"$gwas_phi"  $population  $phi 
# timestamp
#   module purge
#   module load PLINK/2.00-alpha2-x86_64
# 
#     for pop in ${population//,/ } ; do 
#     echo "$pop"
#      for chrom in $(seq 1 22);do
# timestamp
#        plink2 --bfile $bfiles/mcps-subset-chr$chrom \
#       --score $prs_result_dir/"$gwas_phi"/prscsx_"$pop"_effect_"$phi".txt \
#       1 3 5  no-mean-imputation cols=+scoresums list-variants --out  $prs_result_dir/"$gwas_phi"/score_"$chrom"_"$pop"& 
# 
#       done
#       wait
#     done
# module load  R/4.2.1-foss-2022a
# timestamp
# Rscript $script_dir/0.7.combine_chromosome_effect.R $prs_result_dir/"$gwas_phi"  $population  $phi 
# 









