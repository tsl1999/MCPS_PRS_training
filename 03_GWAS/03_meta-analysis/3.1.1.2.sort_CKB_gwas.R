rm(list=ls())
library(data.table)
library(dplyr)
library(stringr)

# data readin-------------------------------------------
data_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
CKB<-data.frame(fread(paste(data_directory,"/metal_RC_IHD.txt",sep="")))
CKB$marker_no_allele<-paste("chr",CKB$CHR,":",CKB$BP,sep="")
CKB$miss_pop<-str_count(CKB$DIR,fixed("?"))
CKB_case<-13748
CKB_control<-62107
CKB_N<-CKB_case+CKB_control

CKB$N<-round(CKB_N*((10-CKB$miss_pop)/10))
CKB$case<-round(CKB_case*((10-CKB$miss_pop)/10))
CKB$control<-round(CKB_control*((10-CKB$miss_pop)/10))
colnames(CKB)[c(2:9)]<-c("chr","position","pval","effect_allele",
                         "non_effect_allele","beta","se","effect_allele_freq")
write.table(CKB,paste(data_directory,"/CKB_IHD_meta-analysis_input.txt",sep=""),quote = F,col.names = T,row.names = F)
