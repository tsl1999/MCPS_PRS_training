rm(list=ls())
library(data.table)
library(dplyr)

#This script will run for every fold and full_training data-----------------------------------

#pocess gwas
arg = commandArgs(trailingOnly=TRUE)
input_files<-strsplit(arg[3],split=",")[[1]]
cat("creating directory...",paste(arg[1],"/run_MR-MEGA/",arg[4],sep=""))
dir.create(file.path(paste(arg[1],"/run_MR-MEGA/",arg[4],sep="")))
cat("creating directory...",paste(arg[2],"/meta-analysis/",sep=""))
dir.create(file.path(paste(arg[2],"/meta-analysis/",sep="")))
cat("write to file ...",paste(arg[1],"/run_MR-MEGA/",arg[4],"/mr-mega_",arg[5],"_",arg[4],".txt",sep=""))
sink(paste(arg[1],"/run_MR-MEGA/",arg[4],"/mr-mega_",arg[5],"_",arg[4],".in",sep=""))
cat(paste(arg[2],"/data_mcps_meta-analysis_input.txt",sep=""))
for(i in 1:length(input_files)){
  cat("\n",input_files[i])
}


sink()