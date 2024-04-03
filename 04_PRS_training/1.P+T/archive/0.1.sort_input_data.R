rm(list=ls())
library(data.table)
library(dplyr)


arg = commandArgs(trailingOnly=TRUE)
working_directory<-arg[1]

#working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis"

#data<-fread(paste(working_directory,"/mr-mega_ukb_cc4d.result",sep=""))
data<-fread(paste(working_directory,"/",arg[2],sep=""))
data$snpID<-paste(data$MarkerName,":",toupper(data$Allele2),":",toupper(data$Allele1),sep="")
data_all_matched<-data[!data$Direction %flike% "?",]

filename<-gsub("1.txt","",arg[2])

write.table(data,paste(working_directory,"/",filename,"_updated.txt",sep=""),quote = F,row.names = F,sep="\t")
write.table(data_all_matched,paste(working_directory,"/",filename,"_updated_allmatched.txt",sep=""),
            quote=F,row.names = F,sep="\t")

