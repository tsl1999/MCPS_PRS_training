#!/usr/bin/python -O
# Jason Matthew Torres
'''
Description: This script runs the second step of the regenie method for conducting
GWAS (i.e. variant-level genetic association tests, adjusted for genome-wide genetic variation)

Output:
The output files are the per-chromosome loco files that are required as input
for step 2 of regenie (i.e. variant-level association testing)

Usage:
module load Python/3.7.4-GCCcore-8.3.0
python 03.2.2_regenie-step2.py pheno_type bgen_compatable_qc_variant_file pheno_file covar_file output_directory

Note: pheno_type is the type of trait for the outcome phenotype of interest,
must be either "quantitative" or "binary"

Note: qc_variant_file is the full file path to the qc_variants.txt generated
from 02.1_extract-qc-variants.py script

Note: output_directory is the directory where the output directories and files
will be written, importantly, this should be same output directory as that used
in 03.1.1 script

Example:
python 03.2.2_regenie-step2.py quantitative qc_variant_dir/qc_variants_bgen-compatable.txt pheno_dir/pheno.txt pheno_dir/covar.txt regenie_gwas_bmi
'''
# libraries
import sys,os
import subprocess as sp

pheno_type = sys.argv[1]
if pheno_type == "binary":
    optional_flag="--bt  --firth  --approx  --pThresh 0.01"
elif pheno_type == "quantitative":
    optional_flag=""
else:
    raise ValueError("pheno_type must be either 'quantitative' or 'binary'")

qc_variant_file = sys.argv[2]
if os.path.isfile(qc_variant_file)!=True:
    raise TypeError("The provided qc variant file does not exist")

pheno_file = sys.argv[3]
if os.path.isfile(pheno_file)!=True:
    raise TypeError("The provided phenotype file does not exist")
else:
    l = open(pheno_file,'r').readline().strip().split()
    if l[0]!="FID" or l[1]!="IID":
        raise ValueError("The first two columns of phentype file "+\
        "must be named 'FID' and 'IID' (i.e. family and indviduals ids)")

covar_file = sys.argv[4]
if os.path.isfile(covar_file)!=True:
    raise TypeError("The provided phenotype file does not exist")
else:
    l = open(covar_file,'r').readline().strip().split()
    if l[0]!="FID" or l[1]!="IID":
        raise ValueError("The first two columns of covariate file "+\
        "must be named 'FID' and 'IID' (i.e. family and indviduals ids)")

output_directory = sys.argv[5]
if output_directory[-1]!="/":
    output_directory = output_directory+"/"
if os.path.isdir(output_directory)!= True:
    raise ValueError("The required output directory does not exist. "+\
    "Did you already run step 1? If so, be sure to use the same output directory here")

regenie="/well/emberson/shared/software/regenie-3.1.3/regenie"
impute_dir = "/well/emberson/projects/mcps/data/genetics_regeneron/"+\
"freeze_150k/data/imputation/"
bgen_file = impute_dir+"MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.bgen"
samp_file = impute_dir+"MCPS_Freeze_150.GT_hg38.pVCF.rgcpid.QC2.TOPMED_dosages.COLLAB.sample"

def make_command_string(chromo):
    command_string='''
%s \
  --step 2 \
  --bgen %s \
  --sample %s \
  --covarFile %s \
  --phenoFile %s \
  --extract %s \
  --bsize 200 %s \
  --pred %s \
  --chr %s \
  --minMAC 1 \
  --out %s
''' % (regenie,bgen_file,samp_file,covar_file,pheno_file,qc_variant_file,\
optional_flag,output_directory+"output_files/regenie-step1_pred.list",\
str(chromo),output_directory+"output_files/regenie-step2-chr"+str(chromo))
    return(command_string)

def step_2_job(chromo): #-chr22_
    command_string = make_command_string(chromo)
    gzip_command_string = "gzip -f " + output_directory+"output_files/*-step2-chr"+str(chromo)+"_*.regenie"
    script = '''#!/bin/bash
#SBATCH -A emberson.prj
#SBATCH -J regenie-step2-chr%s
#SBATCH -p short
#SBATCH -c 1
#SBATCH -o %s.out
#SBATCH -e %s.err

echo "------------------------------------------------"
echo "Run on host: "`hostname`
echo "Operating system: "`uname -s`
echo "Username: "`whoami`
echo "Started at: "`date`
echo "------------------------------------------------"

module purge
module load zlib/1.2.11-GCCcore-9.2.0
%s
%s
  ''' % (str(chromo),output_directory+"logs/regenie-step2-chr"+str(chromo),\
  output_directory+"logs/regenie-step2-chr"+str(chromo),command_string,gzip_command_string)
    fout = open(output_directory+"jobs/regenie-step2-chr"+str(chromo)+"_job.sh",'w')
    fout.write(script)
    fout.close()
    command = ["sbatch","-A","emberson.prj",output_directory+"jobs/regenie-step2-chr"+str(chromo)+"_job.sh"]
    sp.check_call(command)

def main():
    chrom_list = [str(i) for i in range(1,23)]
    chrom_list.append("X")
    for chrom in chrom_list:
        step_2_job(chrom)
    sys.stdout.write("regenie step 2 jobs have been submitted to BMRC short.qc\n")
    sys.stdout.write("You can monitor jobs status with 'squeue -u `whoami'\n")
    sys.stdout.write("If jobs complete run without issue, you can proceed to " + \
    "downstream analyses of GWAS results\n")


if (__name__=="__main__"):
     main()
