#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="regenie_full"
#SBATCH  -p short
#SBATCH --mem=100GB
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/regenie_downstream.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/full/regenie_downstream.err
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
PHENODIR=$CURDIR/Training_data
QCDIR=$PHENODIR/qc_variants
OUTPUTDIR=$CURDIR/Training_data/gwas_regenie
WORKFLOWDIR1=$CURDIR/03_GWAS/00_workflow ##1000 block size
WORKFLOWDIR2=/well/emberson/shared/workflows/gwas/topmed-imputed
module load Python/3.7.4-GCCcore-8.3.0

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

echo step 3 downstream analysis done

current_date_time="`date "+%Y-%m-%d %H:%M:%S"`"
echo $current_date_time