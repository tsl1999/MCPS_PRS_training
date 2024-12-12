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


his<-data.frame(fread(paste(data_directory,"/HISLA_CHD_ALL_ADULT_Feb24_STAGE11.txt",sep="")))
his_case<-20450
his_control<-124432
his_all<-his_case+his_control
his$control<-round((his$TOTAL_N/his_all)*his_control)
his$case<-round((his$TOTAL_N/his_all)*his_case)
his$chr<-as.numeric(sub(":.*", "", his$MarkerName))
his$position<-as.numeric(sub("^[^:]*:([^:]*):.*", "\\1", his$MarkerName))
his$position<-format(his$position,scientific = FALSE)
his$Allele1<-toupper(his$Allele1)
his$Allele2<-toupper(his$Allele2)
his$miss_pop<-str_count(his$Direction,fixed("?"))
his$marker_no_allele<-paste("chr",his$chr,":",his$position,sep="")
colnames(his)[c(2:4,8:10,16,19:20)]<-c("effect_allele","non_effect_allele","effect_allele_freq",
                                    "beta","se","pval","N","chr","position")
write.table(his,paste(data_directory,"/HIS_meta-analysis_input.txt",sep=""),quote = F,col.names = T,row.names = F)



