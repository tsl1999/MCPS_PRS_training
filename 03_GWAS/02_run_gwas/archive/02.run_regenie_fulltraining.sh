#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="regenie2_gwas"
#SBATCH  -p long
#SBATCH --mem=100GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/regenie_fulltraining.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/regenie_full_training.err



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
  
  sleep 16h 
  
##step2
echo step2
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time
python $WORKFLOWDIR2/03.2.2_regenie-step2.py binary \
    $QCDIR/qc_variants_bgen-compatable.txt \
  $PHENODIR/pheno_training_CAD_EPA_80.txt \
  $PHENODIR/covar_training_CAD_EPA_80.txt \
  $OUTPUTDIR/CAD_EPA_80_fulltraining
  
  
  sleep 5h
  
##check regenie
echo check outputs
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time
python $WORKFLOWDIR2/03.2.3_check-regenie-output.py  \
  $OUTPUTDIR/CAD_EPA_80_fulltraining

##combine results
module purge
module load R/4.2.1-foss-2022a
echo combine results
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time
Rscript $WORKFLOWDIR2/04.1_combine-gwas-results.R regenie \
   $OUTPUTDIR/CAD_EPA_80_fulltraining/output_files/
  
  
  
##manhattan
current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time
echo manhattan
Rscript $WORKFLOWDIR2/04.2_manhattan-plot.R regenie \
   $OUTPUTDIR/CAD_EPA_80_fulltraining/output_files/ &
  
#maf-qq-plot
echo maf-qq-plot
Rscript $WORKFLOWDIR2/04.3_maf-stratify-qq-plot.R \
  $OUTPUTDIR/CAD_EPA_80_fulltraining/output_files/ &

wait

echo done

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time