rm(list=ls())

#set up libraries--------------------------------
library(data.table)
library(dplyr)
library(bigsnpr)
library(parallel)
arg = commandArgs(trailingOnly=TRUE)
#set up working paths-----------------------------
NCORES <- nb_cores()
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred"
genotype_directory<-arg[1]

setwd(working_directory)

snp_readBed(paste(genotype_directory,"/mcps-subset-chr",arg[2],".bed",sep=""))
