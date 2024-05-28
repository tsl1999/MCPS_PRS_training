#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH  -p short
#SBATCH --mem-per-cpu=15G
#SBATCH --cpus-per-task=5
#SBATCH --ntasks=22
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/3.PRS-CSx/out/fold%a/prscsx%x.out



CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/prscsx
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
software_dir=$CURDIR/Software/PRScsx
log_dir=$script_dir/out/fold$SLURM_ARRAY_TASK_ID
LDreference=$CURDIR/external_data/LD_reference

export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS



module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"

#conda activate 
conda activate prscsx

mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID
mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID/$SLURM_JOB_NAME




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
--phi="$1" \
--out_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID/$SLURM_JOB_NAME \
--out_name=prscsx \
--meta=TRUE \
--seed=1000 &
done 

wait





















#to run PRS-CSx, first clone the github repo on to your
#git clone https://github.com/getian107/PRScsx.git
#download LD reference and extract files (1kg or ukb)
#tar -xvzf ...tar.gz
#create conda environment as the programme is running under python and some packages are required
#conda install anaconda::h5py
#conda install anaconda::scipy

#cut -d " " -f 17,5,4,10,11 $mcps_gwas_dir/data_mcps_meta-analysis_input.txt > $mcps_gwas_dir/data_mcps_prscsx.txt 
#awk '{ print $17 " " $5 " " $4 " " $10 " " $11}' $mcps_gwas_dir/data_mcps_meta-analysis_input.txt > $mcps_gwas_dir/data_mcps_prscsx.txt 
#sed -i  -e '1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' -e '1s/beta/BETA/' -e '1s/se/SE/' $mcps_gwas_dir/data_mcps_prscsx.txt 
 
#first extract column of choice and then change name
# awk '{ print $17 " " $5 " " $4 " " $10 " " $11}' \
# $mcps_gwas_dir/data_mcps_meta-analysis_input.txt | sed   -e \
# '1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' \
# -e '1s/beta/BETA/' -e '1s/se/SE/'  > $mcps_gwas_dir/data_mcps_prscsx.txt 
# 
# 
