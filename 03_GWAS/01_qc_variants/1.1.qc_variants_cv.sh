#!/bin/bash
#SBATCH --job-name="qc-cv"
#SBATCH --mem-per-cpu=100G
#SBATCH --array=1-10
#SBATCH --output=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/01_qc_variants/out/qc_variant_CAD_EPA_80_cv_fold%a.out


echo this is the qc_variant log file for the $SLURM_ARRAY_TASK_ID th fold

module purge
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/
WORKFLOWDIR=/well/emberson/shared/workflows/gwas/topmed-imputed
PHENODIR=/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID

module load Python/3.7.4-GCCcore-8.3.0
source /well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_venv/bin/activate

mkdir $PHENODIR/qc_variants

python $WORKFLOWDIR/02.1_extract-qc-variants.py binary \
  $PHENODIR/cases_gwas_CAD_EPA_$SLURM_ARRAY_TASK_ID.txt $PHENODIR/qc_variants
  
python $WORKFLOWDIR/02.2_bgen-compatability.py $PHENODIR/qc_variants
python $WORKFLOWDIR/02.3_sugen-compatability.py $PHENODIR/qc_variants