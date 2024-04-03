rm(list=ls())
library(data.table)
library(dplyr)

#This script will run for every fold and full_training data-----------------------------------

#pocess gwas
arg = commandArgs(trailingOnly=TRUE)

#output metal script--------------------------------------------------------------------------
# arg[3]<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources/cc4d_1KG_additive_2015_METAL_input.txt,/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources/CAD_UKBIOBANK_METAL_input.txt"
# arg[4]<-"fulltraining"#directory name
# arg[5]<-"cc4d_ukb"#file ending
input_files<-strsplit(arg[3],split=",")[[1]]

setwd(arg[1])
cat("creating directory...",paste(arg[1],"/run_metal/",arg[4],sep=""))
dir.create(file.path(paste(arg[1],"/run_metal/",arg[4],sep="")))
cat("creating directory...",paste(arg[2],"/meta-analysis/",sep=""))
dir.create(file.path(paste(arg[2],"/meta-analysis/",sep="")))

cat("write to file ...",paste(arg[1],"/run_metal/",arg[4],"/metal_",arg[5],"_",arg[4],".txt",sep=""))
sink(paste(arg[1],"/run_metal/",arg[4],"/metal_",arg[5],"_",arg[4],".txt",sep=""))
cat("#This is the file to run METAL for GWAS meta-analysis\n
## Note for users:\n
#The METAL module stores in the BMRC is the 2011 version and it only takes SNP name\n
#the new github development version takes chromosome ID and name.\n
#To install the latest version in your own directory, refer to the website:\n
#https://github.com/statgen/METAL\n
# For installation of the github version, CMake cross-platform make system is needed\n
# and you can create an anaconda virtual environment, activate it and install cmake using the code:\n
# conda install anaconda::cmake \n
# then follow the direction on their github page\n
## Modules to load before running metal:Python3\n

CUSTOMVARIABLE TotalSampleSize \
LABEL TotalSampleSize as N \
CUSTOMVARIABLE case \
CUSTOMVARIABLE control \
SCHEME   STDERR\
AVERAGEFREQ ON\
MINMAXFREQ ON\
TRACKPOSITIONS ON\n")

#first process mcps data

cat("\n# describe MCPS GWAS feature\n
MARKER marker_no_allele\
CHROMOSOMELABEL chr\
POSITIONLABEL position\
ALLELE   effect_allele non_effect_allele\
FREQ     effect_allele_freq\
WEIGHT N\
LABEL TotalSampleSize as N \
EFFECT   beta\
STDERR   se\
PVAL     pval\n")

cat("\nPROCESS ",paste(arg[2],"/data_mcps_meta-analysis_input.txt",sep="") )

#process other GWAS sources
for  (i in 1: length (input_files)){
  cat("\n\n#describe GWAS feature of ... ",
      gsub("/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources/","",input_files[i]))
  cat("\n\nMARKER marker_no_allele\
CHROMOSOMELABEL chr\
POSITIONLABEL position\
ALLELE   effect_allele non_effect_allele\
FREQ     effect_allele_freq\
EFFECT   beta\
LABEL TotalSampleSize as N \
STDERR   se\
PVAL     pval\n")
  
  data_in<-fread(input_files[i],nrows = 10)
  if(sum(colnames(data_in)=="N")==1){
    cat("WEIGHT N\n")
    cat("\nPROCESS ", input_files[i])
    
  }else(
    cat("\nPROCESS ", input_files[i])
  )
  
  
}

#run metal analysis code
cat("\n\n# Execute meta-analysis\n")
cat("OUTFILE", paste(arg[2],"/meta-analysis/metal_",arg[5],sep=""), ".txt ")
cat("\nANALYZE")
cat("\nQUIT")
sink() 

