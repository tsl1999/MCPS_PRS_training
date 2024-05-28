#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -J post-rsid
#SBATCH  -p long
#SBATCH --mem=50gb
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/prscsx_combine_submission.out

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
#prs_result_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
prs_result_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
bfiles=$CURDIR/data/bfiles/fold$SLURM_ARRAY_TASK_ID


mcps_bbj_pop=AMR,EAS,META
mcps_ukb_pop=AMR,EUR,META
mcps_bbj_ukb_pop=AMR,EAS,EUR,META
mcps_bbj_eur_pop=AMR,EAS,EUR,META

for phi in 1e-06 1e-04 1e-02 1 ; do
for gwas in mcps_bbj mcps_ukb mcps_bbj_ukb mcps_bbj_eur; do
var="${gwas}_pop"
echo ${!var}
 module load  R/4.2.1-foss-2022a
 Rscript $script_dir/1.2.1.combine_prscsx_effect.R $prs_result_dir/"$gwas"_"$phi"  ${!var}  $phi 

  module purge
  module load PLINK/2.00-alpha2-x86_64

    for pop in ${!var//,/ } ; do 
    echo "$pop"
     for chrom in $(seq 1 22);do

       plink2 --bfile $bfiles/mcps-subset-chr$chrom \
      --score $prs_result_dir/"$gwas"_"$phi"/prscsx_"$pop"_effect_"$phi".txt \
      1 3 5  no-mean-imputation cols=+scoresums list-variants --out  $prs_result_dir/"$gwas"_"$phi"/score_"$chrom"_"$pop"

      done
    done
module load  R/4.2.1-foss-2022a
Rscript $script_dir/1.2.2.combine_chromosome_effect.R $prs_result_dir/"$gwas"_"$phi"  ${!var}  $phi 

done
done

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo done

# 1e-04 1e-02 1   mcps_ukb mcps_bbj_ukb
# phi=1e-06
# gwas=mcps_bbj
# module purge
# module load PLINK/2.00-alpha2-x86_64
# for chrom in $(seq 1 22);do
# 
# plink2 --bfile $bfiles/mcps-subset-chr$chrom \
# --score $prs_result_dir/"$gwas"_"$phi"/prscsx_META_effect_1e-06.txt \
# 1 3 5  no-mean-imputation cols=+scoresums list-variants --out  $prs_result_dir/"$gwas"_"$phi"/score_$chrom
# 
# done
# 
# 1e-06 1e-04 1e-02
# 
# 
# 
