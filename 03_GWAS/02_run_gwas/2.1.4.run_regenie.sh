#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="regenie_full"
#SBATCH  -p long
#SBATCH --mem=5GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/run_regenie.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/run_regenie.err

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas
cd $CURDIR
echo $PWD

sbatch $CURDIR/2.1.1.run_regenie_step1.sh

sleep 30s
step1_id=$( grep -Po '^Submitted batch job \K.*' $CURDIR/out/full/regenie_step1.out )
echo step 1 regenie job id is $step1_id

## do not exit until this job is executed
sbatch --wait --dependency=afterok:$step1_id $CURDIR/2.1.2.run_regenie_step2.sh

sleep 30s
step2_id=$(grep -Po '^Submitted batch job \K.*' $CURDIR/out/full/regenie_step2.out|awk '{printf "%s%s",sep,$0; sep=","} END{print ""}' |tr '\n' ' ')

echo step 2 regenie job ids are $step2_id
sbatch --wait --dependency=afterok:$step2_id $CURDIR/2.1.3.run_regenie_downstream.sh


current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done