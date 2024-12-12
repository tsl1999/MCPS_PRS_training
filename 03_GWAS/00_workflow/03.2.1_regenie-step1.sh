#!/bin/bash
#SBATCH -A emberson.prj
#SBATCH -J regenie1
#SBATCH -p long
#SBATCH -c 6


# '''
# Description: This script runs the first step of the regenie method for conducting
# GWAS (i.e. genome-wide regression using only directly-genotyped variants)
# 
# Output:
# The output files are the per-chromosome loco files that are required as input
# for step 2 of regenie (i.e. variant-level association testing)

# 
# Note: pheno_type is the type of trait for the outcome phenotype of interest,
# must be either "quantitative" or "binary"
# 
# Note: output_directory is the directory where the output files will be written

cov_feature="$1"
pheno_file="$2"
covar_file="$3"
output_folder="$4"
bsize=1000
regenie=/well/emberson/shared/software/regenie-3.1.3/regenie
geno_dir=/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/GSAv2_CHIP/pVCF/revised_qc
geno_pre=$geno_dir/MCPS_Freeze_150.GT_hg38.pVCF.revised_qc.autosomes-and-chrX_mac100
covarCol=""
shift 4
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
       -gpre|--geno_pre)
            geno_pre="$2"
            shift
            ;;
       -covarCol|--covarCol)
            covarCol="$2"
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
  optional_flag="--bt"
elif [ $cov_feature = quantitative ]
then
  optional_flag=""
else
 echo pheno_type must be either 'quantitative' or 'binary'
 exit 1
fi

#check for pheno and covar files---------------------------------
if [ ! -f $pheno_file ] 
then 
echo pheno file does not exist
exit 1
else 
header1=$(awk '{ print $1}' $pheno_file|head -n1 )
header2=$(awk '{ print $2}' $pheno_file|head -n1 )
if [ \( $header1 != FID \)  -o  \( $header2 != IID \) ]
then echo The first two columns of phentype file must be named FID and IID '(i.e. family and indviduals ids)'
exit 1
fi
fi


if [ ! -f $covar_file ]
then 
echo covariate file does not exist
exit 1
else 
header3=$(awk '{ print $1}' $covar_file|head -n1 )
header4=$(awk '{ print $2}' $covar_file|head -n1 )
if  [ \( $header3 != FID \)  -o  \( $header4 != IID \) ]
then The first two columns of covariate file must be named FID and IID '(i.e. family and indviduals ids)']
fi
fi

#if there is covarcol, use it------------------------------------
if [ -z $covarCol ]
then 
covarColumn=""
else
covarColumn="--covarCol "$covarCol
fi


mkdir $output_folder


#regenie----------------------------------------------------

module purge
module load zlib/1.2.11-GCCcore-9.2.0

$regenie   --step 1   \
--bed $geno_pre   \
--covarFile $covar_file  \
--phenoFile $pheno_file   \
--bsize $bsize \
$optional_flag $covarColumn \
--lowmem  \
--lowmem-prefix $output_folder/regenie-step1_tmp_rg   \
--out $output_folder/regenie-step1 





#check for pheno column name---------------------------------
# header1=$(awk '{ print $1}' $pheno_file|head -n1 )
# header2=$(awk '{ print $2}' $pheno_file|head -n1 )
# header3=$(awk '{ print $1}' $covar_file|head -n1 )
# header4=$(awk '{ print $2}' $covar_file|head -n1 )
# 
# if [ \( $header1 != FID \)  -o  \( $header2 != IID \) ]
# then 
# echo The first two columns of phentype file must be named FID and IID '(i.e. family and indviduals ids)'
# exit 1
# elif [ \( $header3 != FID \)  -o  \( $header4 != IID \) ]
# then
# echo The first two columns of covariate file must be named FID and IID '(i.e. family and indviduals ids)'
# exit 1
# else
# echo pheno file and covariate file passed checking
# fi
