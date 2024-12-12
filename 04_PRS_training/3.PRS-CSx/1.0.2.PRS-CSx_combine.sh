#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p short
#SBATCH --mem-per-cpu=15G
#SBATCH  -c 2
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/prscsx%x.out

phi="$1"
gwas_phi="$2"
population="$3"
foldn="$4"
timestamp() {
  date "+%Y-%m-%d %H:%M:%S" # current time
}
timestamp
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
prs_result_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$foldn
bfiles=$CURDIR/data/bfiles/fold$foldn


#module load  R/4.2.1-foss-2022a
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate R4.2.1

 Rscript $script_dir/0.6.combine_prscsx_effect.R $prs_result_dir/"$gwas_phi"  $population  $phi 
timestamp
  module purge
  module load PLINK/2.00-alpha2-x86_64

    for pop in ${population//,/ } ; do 
    echo "$pop"
     for chrom in $(seq 1 22);do
timestamp
       plink2 --bfile $bfiles/mcps-subset-chr$chrom \
      --score $prs_result_dir/"$gwas_phi"/prscsx_"$pop"_effect_"$phi".txt \
      1 3 5  no-mean-imputation cols=+scoresums list-variants --out  $prs_result_dir/"$gwas_phi"/score_"$chrom"_"$pop"& 

      done
      wait
    done
module load  R/4.2.1-foss-2022a
timestamp
Rscript $script_dir/0.7.combine_chromosome_effect.R $prs_result_dir/"$gwas_phi"  $population  $phi 
