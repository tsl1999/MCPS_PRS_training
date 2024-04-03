rm(list=ls())

#set up libraries--------------------------------
library(data.table)
library(dplyr)
library(bigsnpr)
library(parallel)
arg = commandArgs(trailingOnly=TRUE)
#set up working paths-----------------------------

working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred"
genotype_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles"

setwd(working_directory)

cat("chromosome",arg[1])
snp_readBed(paste(genotype_directory,"/mcps-freeze150k_qcd_chr",arg[1],".bed",sep=""))
  
cat("done")