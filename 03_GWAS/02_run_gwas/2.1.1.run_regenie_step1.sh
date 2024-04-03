#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="regenie_full"
#SBATCH  -p short
#SBATCH --mem=5GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/regenie_step1.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/regenie_step1.err
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
PHENODIR=$CURDIR/Training_data
QCDIR=$PHENODIR/qc_variants
OUTPUTDIR=$CURDIR/Training_data/gwas_regenie
WORKFLOWDIR1=$CURDIR/03_GWAS/00_workflow ##1000 block size
WORKFLOWDIR2=/well/emberson/shared/workflows/gwas/topmed-imputed
module load Python/3.7.4-GCCcore-8.3.0


#step1
echo step1
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time
python $WORKFLOWDIR1/03.2.1_regenie-step1.py binary \
  $PHENODIR/pheno_training_CAD_EPA_80.txt \
  $PHENODIR/covar_training_CAD_EPA_80.txt \
  $OUTPUTDIR/CAD_EPA_80_fulltraining
  
  
echo step 1 job submission done 
