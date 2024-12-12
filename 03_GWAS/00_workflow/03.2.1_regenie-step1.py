#!/usr/bin/python -O
# Jason Matthew Torres
'''
Description: This script runs the first step of the regenie method for conducting
GWAS (i.e. genome-wide regression using only directly-genotyped variants)

Output:
The output files are the per-chromosome loco files that are required as input
for step 2 of regenie (i.e. variant-level association testing)

Usage:
module load Python/3.7.4-GCCcore-8.3.0
python 03.2.1_regenie-step1.py pheno_type pheno_file covar_file output_directory

Note: pheno_type is the type of trait for the outcome phenotype of interest,
must be either "quantitative" or "binary"

Note: output_directory is the directory where the output files will be written

Example:
python 03.2.1_regenie-step1.py quantitative pheno_dir/pheno.txt pheno_dir/covar.txt regenie_gwas_bmi
'''
# libraries
import sys,os
import subprocess as sp

pheno_type = sys.argv[1]
if pheno_type == "binary":
    optional_flag="--bt"
elif pheno_type == "quantitative":
    optional_flag=""
else:
    raise ValueError("pheno_type must be either 'quantitative' or 'binary'")

pheno_file = sys.argv[2]
if os.path.isfile(pheno_file)!=True:
    raise TypeError("The provided phenotype file does not exist")
else:
    l = open(pheno_file,'r').readline().strip().split()
    if l[0]!="FID" or l[1]!="IID":
        raise ValueError("The first two columns of phentype file "+\
        "must be named 'FID' and 'IID' (i.e. family and indviduals ids)")

covar_file = sys.argv[3]
if os.path.isfile(covar_file)!=True:
    raise TypeError("The provided phenotype file does not exist")
else:
    l = open(covar_file,'r').readline().strip().split()
    if l[0]!="FID" or l[1]!="IID":
        raise ValueError("The first two columns of covariate file "+\
        "must be named 'FID' and 'IID' (i.e. family and indviduals ids)")

output_directory = sys.argv[4]
if output_directory[-1]!="/":
    output_directory = output_directory+"/"
if os.path.isdir(output_directory)!= True:
    os.makedirs(output_directory)
    os.makedirs(output_directory+"output_files/")
    if os.path.isdir(output_directory+"jobs/")!=True:
        os.makedirs(output_directory+"jobs/")
    if os.path.isdir(output_directory+"logs/")!=True:
        os.makedirs(output_directory+"logs/")

regenie="/well/emberson/shared/software/regenie-3.1.3/regenie"

geno_dir = "/well/emberson/projects/mcps/data/genetics_regeneron/"+\
"freeze_150k/data/GSAv2_CHIP/pVCF/revised_qc/"
geno_pre = geno_dir+"MCPS_Freeze_150.GT_hg38.pVCF.revised_qc.autosomes-and-chrX_mac100"

###geno_dir = "/well/emberson/projects/mcps/data/genetics_regeneron/"+\
###"freeze_150k/data/GSAv2_CHIP/phased_vcf_fixref/plink_version_unphased/"
##geno_pre = geno_dir+"mcps_freeze150k_gsav2_qcd_unphased_autosomes-chrX_mac100"

command_string='''
%s \
  --step 1 \
  --bed %s \
  --covarFile %s \
  --phenoFile %s \
  --bsize 1000 %s \
  --lowmem \
  --lowmem-prefix %s_tmp_rg \
  --out %s
''' % (regenie,geno_pre, covar_file, pheno_file,optional_flag,\
output_directory+"output_files/regenie-step1",\
output_directory+"output_files/regenie-step1")

def step_1_job():
    script = '''#!/bin/bash
#SBATCH -A emberson.prj
#SBATCH -J regenie-step1
#SBATCH -p long
#SBATCH --time=1-10:00:00
#SBATCH -c 6
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
  ''' % (output_directory+"logs/regenie-step1",output_directory+\
  "logs/regenie-step1",command_string)
    fout = open(output_directory+"jobs/regenie-step1_job.sh",'w')
    fout.write(script)
    fout.close()
    command = ["sbatch","-A","emberson.prj",output_directory+"jobs/regenie-step1_job.sh"]
    sp.check_call(command)
    sys.stdout.write("regenie step 1 job has been submitted to BMRC long.qc\n")
    sys.stdout.write("You can monitor job status with 'squeue -u `whoami`'\n")
    sys.stdout.write("If job completes run without issue, you can proceed to " + \
    "regenie step 2\n")

def main():
    step_1_job()


if (__name__=="__main__"):
     main()
