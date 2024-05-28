#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="cv_regenie"
#SBATCH  -p long
#SBATCH --mem=5GB
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/fold%a/run_regenie.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/fold%a/run_regenie.err


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas
cd $CURDIR
echo $PWD

echo fold $SLURM_ARRAY_TASK_ID

#step 1 regenie-----------------------------------
output_path=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_step1.out
error_path=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_step1.err
 
 sbatch  -o "$output_path" -e "$error_path" $CURDIR/2.2.1.run_regenie_step1_cv.sh $SLURM_ARRAY_TASK_ID 

 sleep 100s
step1_id=$( grep -Po '^Submitted batch job \K.*' $output_path)
echo step 1 regenie job id is $step1_id

#step 2 regenie-------------------------

output_path2=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_step2.out
error_path2=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_step2.err
## do not exit until this job is executed
sbatch --wait --dependency=afterok:$step1_id -o "$output_path2" -e "$error_path2" \
$CURDIR/2.2.2.run_regenie_step2_cv.sh $SLURM_ARRAY_TASK_ID
sleep 5m

step2_id=$(grep -Po '^Submitted batch job \K.*' $output_path2|awk '{printf "%s%s",sep,$0; sep=","} END{print ""}' |tr '\n' ' ')

echo step2 regenie job ids are $step2_id

#downstream--------------------
output_path3=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_downstream.out
error_path3=$CURDIR/out/fold$SLURM_ARRAY_TASK_ID/regenie_downstream.err

sbatch --wait --dependency=afterok:$step2_id -o "$output_path3" -e "$error_path3" \
$CURDIR/2.2.3.run_regenie_downstream_cv.sh $SLURM_ARRAY_TASK_ID


current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done