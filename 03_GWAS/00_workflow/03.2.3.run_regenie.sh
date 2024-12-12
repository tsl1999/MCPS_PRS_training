#!/bin/bash
#SBATCH -A emberson.prj
#SBATCH -J regenie
#SBATCH -p long
#SBATCH -c 6
echo "------------------------------------------------"
echo "Run on host: "`hostname`
echo "Operating system: "`uname -s`
echo "Username: "`whoami`
echo "Started at: "`date`
echo "------------------------------------------------"


timestamp() {
  date "+%Y-%m-%d %H:%M:%S" # current time
}
timestamp

a=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
CURDIR=$(dirname $a) #get workflow directory
echo workflow directory is  $CURDIR


cov_feature="$1" #binary or quantitative
qc_path="$2" #qc file path
pheno_file="$3" #pheno file path
covar_file="$4" #covariates file path
output_folder="$5" #output folder path
shift 5

echo feature is $cov_feature
echo QC variant file is $qc_path
echo phenotype file is $pheno_file
echo covariate file is $covar_file
echo results will be saved to $output_folder
mkdir $output_folder

#optional arguments----------------------------------
bsize=1000 
regenie=/well/emberson/shared/software/regenie-3.1.3/regenie
impute_dir=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/imputation
bgen_file=$impute_dir/MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.bgen
samp_file=$impute_dir/MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.COLLAB.sample
geno_dir=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/GSAv2_CHIP/pVCF/revised_qc
geno_pre=$geno_dir/MCPS_Freeze_150.GT_hg38.pVCF.revised_qc.autosomes-and-chrX_mac100
covarCol=""
phenolist=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -bsize|--blocksize)
            bsize="$2"
            shift
            ;;
        -regenie|--regenie_path)
            regenie="$2"
            shift
            ;;
       -impute|--impute_dir)
            impute_dir="$2"
            shift
            ;;
       -bgen|--bgen_file)
            bgen_file="$2"
            shift
            ;;
       -samp|--sample_file)
            samp_file="$2"
            shift
            ;;
      -gpre|--geno_pre)
            geno_pre="$2"
            shift
            ;;
       -covarCol|--covarCol)
            covarCol="$2"
            shift
            ;;
       -phenolist|--phenoColList)
            phenolist="$2"
            shift
            ;;           
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done


# check covar col-----------------------
if [ -z $covarCol ]
then 
covarColumn=""
else
covarColumn="--covarCol "$covarCol
fi


#check phenolist------------------------

if [ -z $phenolist ]
then 
phenocollist=""
else 
if [ ! -f $phenolist ]
then 
echo pheno column list file does not exist
exit 1
else
phenocollist="--phenoColList "$phenolist
fi
fi


output_name=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/StdOut=/{print $2}')
outputfile_path=$(dirname $output_name)
echo output file of slurm scripts will be saved to $outputfile_path

#running regenie----------------------------
echo step 1
 timestamp
bash  $CURDIR/03.2.1_regenie-step1.sh \
$cov_feature $pheno_file $covar_file $output_folder/output_files \
-bsize $bsize -regenie $regenie -gpre $geno_pre

echo step2
#echo checking input files

# bash $CURDIR/03.2.2_regenie-step2_check.sh $cov_feature $qc_path $pheno_file $covar_file $output_folder

echo step 2 running
timestamp
sbatch --wait  -o $outputfile_path/regenie_step2/chr%a.out  \
$CURDIR/03.2.2_regenie-step2_run.sh \
$cov_feature $qc_path $pheno_file \
$covar_file $output_folder/output_files \
-bsize $bsize \
-regenie $regenie \
-impute $impute_dir \
-bgen $bgen_file \
-samp $samp_file $covarColumn $phenocollist



timestamp
echo all jobs done 

##example
# sbatch -o $CURDIR/03_GWAS/out/test_run_regenie.out $WORKFLOWDIR/03.2.3.run_regenie.sh \
# binary $QCDIR/qc_variants_bgen-compatable.txt $PHENODIR/pheno_training_CAD_EPA_80.txt \
# $PHENODIR/covar_training_CAD_EPA_80.txt $OUTPUTDIR/test_CAD_EPA
