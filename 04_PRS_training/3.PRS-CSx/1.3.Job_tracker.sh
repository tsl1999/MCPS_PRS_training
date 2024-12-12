#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="prscsx_jobtracker"
#SBATCH  -p short
#SBATCH --mem=5GB
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/job_tracker.out


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
output_dir=$CURDIR/04_PRS_training/3.PRS-CSx/out


#mcps_bbj mcps_bbj_eur mcps_bbj_ukb mcps_ukb mcps_ukb_ckb mcps_bbj_ukb mcps_eur_eas
for gwas in  his_eur_eas his_eur; do

for phi in auto 1e-07 1e-06 1e-05 1e-04 1e-02 1; do
result=""
for fold in $(seq 1 1 10) ; do
echo parameter set "$gwas"_"$phi"
file=$output_dir/fold$fold/prscsx"$gwas"_"$phi"-submit.out
id_$fold=$(grep -Po '^Submitted batch job \K.*' $file|awk '{printf "%s%s",sep,$0; sep=","} END{print ""}' |tr '\n' ' ')

var_name="id_$fold"
value=${!var_name}
echo ${value}
result+="${value},"
done
result=${result%,}
echo job ids $result
done
done

echo 