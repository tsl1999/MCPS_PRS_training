'''
Jason Matthew Torres , Eirini Trichia

The first column of this file needs to have the SNP ID in GRCh37. 
Output: 
A bed file with the GRCh38 start and end positions. The chromosome position
that needs to be extracted is the start position + 1.

Usage:
WORKFLOWDIR
module load Python/3.7.4-GCCcore-8.3.0 
python $WORKFLOWDIR/02.1_LiftOver-to-GRCh38.py workdir filename

Example:
WORKFLOWDIR=/well/emberson/users/rnd777/MR_workflows/mr/02_SNP-selection-extraction
python $WORKFLOWDIR/02.1_LiftOver-to-GRCh38.py \
    /well/emberson/users/rnd777/adiposity_MR/Fairhurst/HC/input_files/ hm_all_HC_TAMA

'''

# libraries
import sys,os
import subprocess as sp
import argparse
import requests

parser = argparse.ArgumentParser()

# Arguments
def list_of_strings(arg):
    return arg.split(',')

parser.add_argument(
  'workdir',
  type=str,
  help='Directory to for input and ouput of the liftOver SNPs'
  )

parser.add_argument(
  'filename',
  type=str,
  help='Name of the input file'
  )

args = parser.parse_args()
workdir = args.workdir
filename = args.filename

liftover = "/well/emberson/shared/software/liftOver/liftOver" 
chain_file = "/well/emberson/shared/software/liftOver/chain_files/hg19ToHg38.over.chain.gz" 

def lift_to_build38():
   fin = open(workdir+filename+".csv",'r')
   fout = open(workdir+filename+".bed",'w')
   fin.readline() # header
   for line in fin:
    l = line.strip().split(',')
    var = l[0]
    chromo = "chr"+var.split(":")[0]
    bp = int(var.split(":")[1])
    write_list = [chromo,str(bp-1),str(bp),var]
    fout.write("\t".join(write_list)+"\n")
   fin.close()
   fout.close()
   # Run liftover
   input_bed = workdir+filename+".bed"
   output_bed = workdir+filename+"-GRCh38.bed"
   unmapped_file = workdir+filename+"-GRCh38-unmapped"
   command = [liftover,input_bed,chain_file,output_bed,unmapped_file]
   sp.check_call(command) 

def main():
    lift_to_build38()

if (__name__=="__main__"):
    main()
