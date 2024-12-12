#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p short
#SBATCH --mem-per-cpu=15G
#SBATCH  -c 4
#SBATCH --array=1-22

timestamp() {
  date "+%Y-%m-%d %H:%M:%S" # current time
}
timestamp

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/prscsx
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources
software_dir=$CURDIR/Software/PRScsx
LDreference=$CURDIR/external_data/LD_reference
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_"$5"
his_sst=$mcps_gwas_dir/data_mcps_prscsx.txt
his_n=96270


export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS

module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"

conda activate prscsx


phi="$1"

echo fold "$5"
chrom=$SLURM_ARRAY_TASK_ID
echo chromosome $chrom
echo phi "$1"

if [ -z "$7" ]; then

his_sst=$mcps_gwas_dir/data_mcps_prscsx.txt
his_n=96000
else
echo "$7"
his_sst=$mcps_gwas_dir/meta-analysis/"$7"_prscsx.txt
his_n="$8"
fi

if [ $phi = auto ]
then
  srun python $software_dir/PRScsx.py \
--ref_dir=$LDreference \
--bim_prefix=$genotype_files/mcps-freeze150k_rsid_chr$chrom \
--sst_file=$his_sst,"$2" \
--n_gwas="$his_n","$4" \
--pop=AMR,"$3" \
--chrom=$SLURM_ARRAY_TASK_ID \
--out_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold"$5"/"$6" \
--out_name=prscsx \
--meta=TRUE \
--seed=1000
else
srun python $software_dir/PRScsx.py \
--ref_dir=$LDreference \
--bim_prefix=$genotype_files/mcps-freeze150k_rsid_chr$chrom \
--sst_file=$his_sst,"$2" \
--n_gwas="$his_n","$4" \
--pop=AMR,"$3" \
--chrom=$SLURM_ARRAY_TASK_ID \
--phi=$phi \
--out_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold"$5"/"$6" \
--out_name=prscsx \
--meta=TRUE \
--seed=1000
fi
timestamp