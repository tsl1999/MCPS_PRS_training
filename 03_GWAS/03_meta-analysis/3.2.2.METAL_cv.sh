#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="metal-cv"
#SBATCH  -p short
#SBATCH --mem=60GB
#SBATCH --array=1-10
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out/fold%a_metal.out


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
METAL_DIR=$CURDIR/Software/METAL/build/bin
EXTERNAL_GWAS=$CURDIR/external_data/GWAS_sources
mcps_gwas=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis
pheno_dir=$CURDIR/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID



module load R/4.2.1-foss-2022a

Rscript $SCRIPT_DIR/3.0.2.prep_mcps_data.R $mcps_gwas $pheno_dir

wait

module purge

# srun --ntasks=1 --nodes=1 --cpus-per-task=1 bash $SCRIPT_DIR/3.0.4.run_METAL.sh fold_$SLURM_ARRAY_TASK_ID \
# $EXTERNAL_GWAS/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt \
# ukb_cc4d  &
# 
# 
# srun --ntasks=1 --nodes=1 --cpus-per-task=1 bash $SCRIPT_DIR/3.0.4.run_METAL.sh fold_$SLURM_ARRAY_TASK_ID \
# $EXTERNAL_GWAS/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/BBJCAD_2020_ucsc_meta-analysis_input.txt \
# ukb_cc4d_bbj  & 
# 
# srun --ntasks=1 --nodes=1 --cpus-per-task=1 bash $SCRIPT_DIR/3.0.4.run_METAL.sh fold_$SLURM_ARRAY_TASK_ID \
# $EXTERNAL_GWAS/cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/BBJCAD_2020_ucsc_meta-analysis_input.txt \
# cc4d_bbj  &

 bash $SCRIPT_DIR/3.0.4.run_METAL.sh fold_$SLURM_ARRAY_TASK_ID \
$EXTERNAL_GWAS/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/CKB_IHD_meta-analysis_input.txt \
ukb_ckb  

bash $SCRIPT_DIR/3.0.4.run_METAL.sh fold_$SLURM_ARRAY_TASK_ID \
$EXTERNAL_GWAS/CAD_UKBIOBANK_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/CKB_IHD_meta-analysis_input.txt,$EXTERNAL_GWAS/cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt,$EXTERNAL_GWAS/BBJCAD_2020_ucsc_meta-analysis_input.txt  \
ukb_ckb_cc4d_bbj  

#wait

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time
echo metal analysis done