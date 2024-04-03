#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="cv_regenie"
#SBATCH  -p short
#SBATCH --mem=10GB

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
PHENODIR=$CURDIR/Training_data/crossfold/CAD_EPA/"$1"
QCDIR=$PHENODIR/qc_variants
OUTPUTDIR=$CURDIR/Training_data/gwas_regenie
WORKFLOWDIR1=$CURDIR/03_GWAS/00_workflow ##1000 block size
WORKFLOWDIR2=/well/emberson/shared/workflows/gwas/topmed-imputed
module purge
module load Python/3.7.4-GCCcore-8.3.0

##step2
echo running script cv_02.2_run_regenie_step2.sh for fold"$1"

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo time: $current_date_time

python $WORKFLOWDIR1/03.2.2_regenie-step2.py binary \
    $QCDIR/qc_variants_bgen-compatable.txt \
  $PHENODIR/pheno_gwas_CAD_EPA_"$1".txt \
  $PHENODIR/covar_gwas_CAD_EPA_"$1".txt \
  $OUTPUTDIR/CAD_EPA_80_fold_"$1"

echo step 2 job submission done