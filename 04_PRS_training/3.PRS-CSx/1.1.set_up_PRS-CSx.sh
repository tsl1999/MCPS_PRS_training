#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p short
#SBATCH --mem-per-cpu=15G
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=22
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/prscsx%x.out


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


export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS



module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"

#conda activate 
conda activate prscsx

mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID/$SLURM_JOB_NAME


phi="$1"

for chrom in $(seq 1 22);
do 
echo chromosome $chrom
echo phi "$1"
srun --ntasks=1 --nodes=1 --cpus-per-task=$SLURM_CPUS_PER_TASK python $software_dir/PRScsx.py \
--ref_dir=$LDreference \
--bim_prefix=$genotype_files/mcps-freeze150k_rsid_chr$chrom \
--sst_file=$mcps_gwas_dir/data_mcps_prscsx.txt,"$2" \
--n_gwas=96270,"$4" \
--pop=AMR,"$3" \
--chrom=$chrom \
--phi=$phi \
--out_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID/$SLURM_JOB_NAME \
--out_name=prscsx \
--meta=TRUE \
--seed=1000 &
done 

wait


gwas_phi=$SLURM_JOB_NAME
population=AMR,"$3",META

# var="${gwas}_pop"
# echo ${!var}
 module load  R/4.2.1-foss-2022a
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
      1 3 5  no-mean-imputation cols=+scoresums list-variants --out  $prs_result_dir/"$gwas_phi"/score_"$chrom"_"$pop"

      done
    done
module load  R/4.2.1-foss-2022a
timestamp
Rscript $script_dir/0.7.combine_chromosome_effect.R $prs_result_dir/"$gwas_phi"  $population  $phi 










