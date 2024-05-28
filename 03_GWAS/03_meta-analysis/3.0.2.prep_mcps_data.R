rm(list=ls())
library(data.table)
library(dplyr)

#This script will run for every fold and full_training data-----------------------------------

#process gwas
arg = commandArgs(trailingOnly=TRUE)
# arg[1]<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis"
# #arg[2]<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fulltraining"#an argument in bash
# #arg[2]<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fold_1"
# 
# arg[2]<-"/well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_regenie/gwas_regenie_CAD_EPA_80"



data_mcps<-fread(paste(arg[1],"/output_files/combined-gwas-results.txt.gz",sep=""))
data_pheno<-readRDS(paste(arg[2],"/gwas_data.rds",sep=""))
data_mcps$marker<-paste("chr",data_mcps$ID,sep="")
data_mcps$marker_no_allele<-paste("chr",data_mcps$CHROM,":",data_mcps$GENPOS,sep="")
cat("saving data to...",paste(arg[1],"/data_a_mcps_meta-analysis_input.txt",sep=""))
data_mcps$OR<-exp(data_mcps$BETA)
data_mcps$OR_95L<-exp(data_mcps$BETA-1.96*data_mcps$SE)
data_mcps$OR_95U<-exp(data_mcps$BETA+1.96*data_mcps$SE)
colnames(data_mcps)[c(1,2,4,5,6,10,11,15)]<-c("chr","position","non_effect_allele","effect_allele",
                                           "effect_allele_freq","beta","se","pval")

data_mcps$case<-sum(data_pheno$CAD_EPA==1)
data_mcps$control<-sum(data_pheno$CAD_EPA==0)
data_mcps$check<-data_mcps$case+data_mcps$control==data_mcps$N
for(i in 1:nrow(data_mcps)){
  if(data_mcps$check[i]==FALSE){
    prop<-data_mcps$N[i]/(data_mcps$case[i]+data_mcps$control[i])
    data_mcps$case[i]<-data_mcps$case[i]*prop
    data_mcps$control[i]<-data_mcps$control[i]*prop
  }}
#updated version: remove duplicates
data_mcps_up<-data_mcps[!data_mcps$marker_no_allele%in%data_mcps$marker_no_allele[duplicated(data_mcps$marker_no_allele)],]
write.table(data_mcps_up,paste(arg[1],"/data_mcps_meta-analysis_input_nodup.txt",sep=""),col.names = T,row.names = F,quote=F)

