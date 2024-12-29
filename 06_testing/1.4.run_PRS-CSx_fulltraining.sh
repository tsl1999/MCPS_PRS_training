#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J prscsx
#SBATCH  -p short
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/06_testing/out/prscsx_job_submission.out

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/Testing_data/bfiles/prscsx
script_dir=$CURDIR/06_testing
gwas_external_dir=$CURDIR/external_data/GWAS_sources


#mcps=data_mcps_prscsx.txt,AMR,96270
bbj=$gwas_external_dir/BBJCAD_2020_prscsx.txt,EAS,168228
ukb=$gwas_external_dir/CAD_UKBIOBANK_prscsx.txt,EUR,296525
eur=$gwas_external_dir/CC4D_UKB_rsid_prscsx.txt,EUR,480830
eas=$gwas_external_dir/BBJ_CKB_meta_analysis1_prscsx.txt,EAS,244083
ckb=$gwas_external_dir/CKB_IHD_meta-analysis_input_prscsx.txt,EAS,75855

IFS=', ' bbj_var=($bbj)
IFS=', ' ukb_var=($ukb)
IFS=', ' eur_var=($eur)
IFS=', ' ckb_var=($ckb)
IFS=', ' eas_var=($eas)

sbatch  --job-name=his_eur_eas_1e-04 $script_dir/1.3.PRS-CSx_fulltraining.sh \
1e-04 ${eur_var[0]},${eas_var[0]} \
${eur_var[1]},${eas_var[1]} ${eur_var[2]},${eas_var[2]} his_all 251400

sbatch  --job-name=his_eur_eas_1e-02 $script_dir/1.3.PRS-CSx_fulltraining.sh \
1e-02 ${eur_var[0]},${eas_var[0]} \
${eur_var[1]},${eas_var[1]} ${eur_var[2]},${eas_var[2]} his_all 251400


# sbatch  --job-name=mcps_bbj_eur_1e_04 $script_dir/1.3.PRS-CSx_fulltraining.sh \
# 1e-04 ${eur_var[0]},${bbj_var[0]} \
# ${eur_var[1]},${bbj_var[1]} ${eur_var[2]},${bbj_var[2]}
# 
# sbatch  --job-name=mcps_eur_eas_1e_04 $script_dir/1.3.PRS-CSx_fulltraining.sh \
# 1e-04 ${eur_var[0]},${eas_var[0]} \
# ${eur_var[1]},${eas_var[1]} ${eur_var[2]},${eas_var[2]}
# # module load  R/4.2.1-foss-2022a
# 
# 
# Rscript $CURDIR/04_PRS_training/3.PRS-CSx/0.7.combine_chromosome_effect.R \
# $CURDIR/Testing_data/PRS/3.PRS-CSx/mcps_eur_eas_1e-04  AMR,EUR,EAS,META  1e-04
# 
