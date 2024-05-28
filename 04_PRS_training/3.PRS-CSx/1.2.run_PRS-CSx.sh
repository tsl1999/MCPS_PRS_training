#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J prscsx
#SBATCH  -p short
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/prscsx_job_submission.out

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/prscsx
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources


#mcps=data_mcps_prscsx.txt,AMR,96270
bbj=$gwas_external_dir/BBJCAD_2020_prscsx.txt,EAS,168228
ukb=$gwas_external_dir/CAD_UKBIOBANK_prscsx.txt,EUR,296525
ckb=$gwas_external_dir/CKB_IHD_prscsx.txt,EAS,75855
eur=$gwas_external_dir/CC4D_UKB_rsid_prscsx.txt,EUR,480830
eas=$gwas_external_dir/BBJ_CKB_rsid_prscsx.txt,EAS,244083

IFS=', ' bbj_var=($bbj)
IFS=', ' ukb_var=($ukb)
IFS=', ' eur_var=($eur)




for phi in 1e-06  1e-04  1e-02  1;
do

id1=$(sbatch --job-name=mcps_bbj_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${bbj_var[0]} ${bbj_var[1]} ${bbj_var[2]})
echo $id1

id2=$(sbatch --job-name=mcps_ukb_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${ukb_var[0]} ${ukb_var[1]} ${ukb_var[2]})
echo $id2

id3=$(sbatch --job-name=mcps_bbj_ukb_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${bbj_var[0]},${ukb_var[0]} \
${bbj_var[1]},${ukb_var[1]} ${bbj_var[2]},${ukb_var[2]})
echo $id3

id4=$(sbatch --job-name=mcps_bbj_eur_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${bbj_var[0]},${eur_var[0]} \
${bbj_var[1]},${eur_var[1]} ${bbj_var[2]},${eur_var[2]})
echo $id4

id5=$(sbatch --job-name=mcps_ukb_ckb_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${ukb_var[0]},${ckb_var[0]} \
${ukb_var[1]},${ckb_var[1]} ${ukb_var[2]},${ckb_var[2]})
echo $id5


id6=$(sbatch --job-name=mcps_eur_eas_$phi $script_dir/1.1.set_up_PRS-CSx.sh $phi ${eur_var[0]},${eas_var[0]} \
${eur_var[1]},${eas_var[1]} ${eur_var[2]},${eas_var[2]})
echo $id6


done

all_job=$(grep -Po '^Submitted batch job \K.*' $CURDIR/04_PRS_training/3.PRS-CSx/out/prscsx_job_submission.out|awk '{printf "%s%s",sep,$0; sep=","} END{print ""}' |tr '\n' ' ')
echo $all_job


#--format=JobID,Start,End,Elapsed,REQCPUS,ALLOCTRES%30,state
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done


