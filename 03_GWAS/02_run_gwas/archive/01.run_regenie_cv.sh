#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="regenie2_gwas"
#SBATCH  -p long
#SBATCH --mem=100GB
#SBATCH --array=1-10
#SBATCH  -o /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/regenie_fold%a.out
#SBATCH  -e /well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/02_run_gwas/out/regenie_fold%a.err



CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
PHENODIR=$CURDIR/Training_data/crossfold/CAD_EPA/$SLURM_ARRAY_TASK_ID
QCDIR=$PHENODIR/qc_variants
OUTPUTDIR=$CURDIR/Training_data/gwas_regenie
WORKFLOWDIR1=$CURDIR/03_GWAS/00_workflow ##1000 block size
WORKFLOWDIR2=/well/emberson/shared/workflows/gwas/topmed-imputed
module purge
module load Python/3.7.4-GCCcore-8.3.0


#step1
echo step 1
python $WORKFLOWDIR1/03.2.1_regenie-step1.py binary \
  $PHENODIR/pheno_gwas_CAD_EPA_$SLURM_ARRAY_TASK_ID.txt \
  $PHENODIR/covar_gwas_CAD_EPA_$SLURM_ARRAY_TASK_ID.txt \
  $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
  
  
  sleep 1d 10h 
  
##step2
echo step 2
python $WORKFLOWDIR2/03.2.2_regenie-step2.py binary \
    $QCDIR/qc_variants_bgen-compatable.txt \
  $PHENODIR/pheno_gwas_CAD_EPA_$SLURM_ARRAY_TASK_ID.txt \
  $PHENODIR/covar_gwas_CAD_EPA_$SLURM_ARRAY_TASK_ID.txt \
  $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
  
  
  sleep 5h
  
##check regenie
echo check regenie
python $WORKFLOWDIR2/03.2.3_check-regenie-output.py  \
  $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID

##combine results
module purge
module load R/4.2.1-foss-2022a
echo combine results
Rscript $WORKFLOWDIR2/04.1_combine-gwas-results.R regenie \
   $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/output_files/
  
  
  
##manhattan
echo manhattan
Rscript $WORKFLOWDIR2/04.2_manhattan-plot.R regenie \
   $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/output_files/ &
  
#maf-qq-plot
echo maf-qq-plot
Rscript $WORKFLOWDIR2/04.3_maf-stratify-qq-plot.R \
  $OUTPUTDIR/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID/output_files/ &

wait


echo done

##in the future we can change to once the first job done, the second job can run, but this needs to extract first job ID
#job_id=$(sbatch --parsable test.sh)
#echo $job_id
#sbatch --dependency=afterany:14107426 job2.sh, some change on GWAS job submission is needed