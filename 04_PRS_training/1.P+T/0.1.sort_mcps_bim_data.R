rm(list=ls())
library(data.table)
library(dplyr)

working_directory="/well/emberson/projects/mcps/data/genetics_regeneron/freeze_150k/data/imputation/oxford_qcd/per_chromosome/pgen_hds/bfiles"

data_path= "/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles"
for(chromosome in c(1:22,"X")){
  cat("update bim file for chromosome", chromosome)
  data=fread(paste(working_directory,"/mcps-freeze150k_qcd_chr",chromosome,".bim",sep=""))
  colnames(data)<-c("CHROM","ID","V3","POS","MINOR","MAJOR")
  data$ID<-sub( "(^[^:]+[:][^:]+)(.+$)", "\\1",data$ID,perl = T)
  data_no_duplicate<-data[!data$ID%in%data$ID[duplicated(data$ID)],]
  data_duplicate<-data[data$ID%in%data$ID[duplicated(data$ID)],]
  write.table(data,paste(data_path,"/mcps-freeze150k_qcd_chr",chromosome,".bim",sep=""),quote = F,col.names = F,row.names = F,sep="\t")
  write.table(data_duplicate,paste(data_path,"/mcps-freeze150k_qcd_chr",chromosome,"_duplicate.txt",sep=""),quote = F,col.names = F,row.names = F,sep="\t")
}


snp_to_exclude<-c()

for(chromosome in c(1:22,"X")){
  data=fread(paste(data_path,"/mcps-freeze150k_qcd_chr",chromosome,"_duplicate.txt",sep=""))
  snp_to_exclude<-rbind(snp_to_exclude,data)
}

write.table(snp_to_exclude,paste(data_path,"/snp_to_exclude.txt",sep=""),quote = F,col.names = F,row.names = F,sep="\t")

