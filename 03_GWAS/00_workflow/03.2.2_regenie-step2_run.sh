#!/bin/bash
#SBATCH -A emberson.prj
#SBATCH -J regenie-step2
#SBATCH -p short
#SBATCH --mem=20GB
#SBATCH --array=1-23


echo "------------------------------------------------"
echo "Run on host: "`hostname`
echo "Operating system: "`uname -s`
echo "Username: "`whoami`
echo "Started at: "`date`
echo "------------------------------------------------"


module purge
module load zlib/1.2.11-GCCcore-9.2.0

cov_feature="$1"
qc_path="$2"
pheno_file="$3"
covar_file="$4"
output_folder="$5"

#check for trait feature-----------------------------
if [ $cov_feature = binary ]
then
  optional_flag=" --bt --firth  --approx  --pThresh 0.01"
elif [ $cov_feature = quantitative ]
then
  optional_flag=""
else
 echo pheno_type must be either 'quantitative' or 'binary'
 exit 1
fi


#check qc_variant path---------------------------
if [ ! -f $qc_path ]
then  echo QC file does not exist
exit 1
fi


#check pheno file---------------------
if [ ! -f $pheno_file ] 
then
echo pheno file does not exist
exit 1
else
  header1=$(awk '{ print $1}' $pheno_file|head -n1 )
  header2=$(awk '{ print $2}' $pheno_file|head -n1 )
 if [ \( $header1 != FID \)  -o  \( $header2 != IID \) ]
 then 
 echo The first two columns of phentype file must be named FID and IID '(i.e. family and indviduals ids)'
 exit 1
  fi
fi
#check covar file---------------------
if [ ! -f $covar_file ] 
then
echo covar file does not exist
exit 1
else 
header1=$(awk '{ print $1}' $covar_file|head -n1 )
header2=$(awk '{ print $2}' $covar_file|head -n1 )
 if [ \( $header1 != FID \)  -o  \( $header2 != IID \) ]
 then 
 echo The first two columns of phentype file must be named FID and IID '(i.e. family and indviduals ids)'
 exit 1
fi
fi
#check output path--------------------------


if [ ! -d $output_folder ] 
then 
echo The required output directory does not exist. 
echo Did you already run step 1? If so, be sure to use the same output directory here
exit 1
fi



bsize=1000
regenie=/well/emberson/shared/software/regenie-3.1.3/regenie
impute_dir=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/imputation
bgen_file=$impute_dir/MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.bgen
samp_file=$impute_dir/MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.COLLAB.sample
covarCol=""
phenolist=""
shift 5
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


#check for trait feature-----------------------------
if [ $cov_feature = binary ]
then
  optional_flag=" --bt --firth  --approx  --pThresh 0.01"
elif [ $cov_feature = quantitative ]
then
  optional_flag=""
else
 echo pheno_type must be either 'quantitative' or 'binary'
 exit 1
fi

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
phenocollist="--split --phenoColList "$phenolist
fi
fi


 $regenie  --step 2 \
  --bgen  $bgen_file \
  --sample  $samp_file \
  --covarFile $covar_file  \
  --phenoFile  $pheno_file  $covarColumn $phenocollist \
  --extract $qc_path \
  --bsize $bsize   $optional_flag \
  --pred $output_folder/regenie-step1_pred.list \
  --chr $SLURM_ARRAY_TASK_ID \
  --minMAC 1 \
  --out $output_folder/regenie-step2-chr$SLURM_ARRAY_TASK_ID
  
gzip -f $output_folder/*-step2-chr$SLURM_ARRAY_TASK_ID*.regenie
  
  
  
  
  