#!/bin/bash
#SBATCH --job-name="phenotype"
#SBATCH --mem=5GB
#SBATCH --output=phenotype.out


echo start extracting phenotype


CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
WORKFLOWDIR=/well/emberson/shared/workflows/gwas/topmed-imputed

cd CURDIR 
echo $PWD
module load R/3.6.2-foss-2019b

Rscript $WORKFLOWDIR/01.1_extract-phenotype-info.R $CURDIR/data \
SEX,FEMALE,AGE,SMOKE,INCOME,\
BMI,BASE_CHD,BASE_CVD,SBP,DBP,EDU_LEVEL,smokegp2,COYOACAN,BASE_DIABETES,WAISTC,HIPC,\
BASE_CANCER,BASE_EMPHYSEMA,BASE_CIRR,BASE_PEP,BASE_CKD,BASE_PAD,\
WHRATIO,BASE_HBA1C,DRUG_D1,DRUG_D2,DRUG_D3,DRUG_D4,HDL_C,LDL_C,EPA001,EPA001A,\
EPO001,EPO001A,DATE_RECRUITED


echo done
