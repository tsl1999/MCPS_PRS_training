rm(list=ls())
library(data.table)
library(dplyr)
arg = commandArgs(trailingOnly=TRUE)

#set working folder---------------------------------
working_directory<-arg[1]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/3.PRS-CSx/test/mcps_bbj_1e-06"
input_pop<-strsplit(arg[2],split = ",")[[1]]
phi<-arg[3]
for (i in 1:length(input_pop)){
#readin data--------------------------------------
score_file<-fread(paste(working_directory,"/prscsx_",input_pop[i],"_effect_",phi,".txt",sep=""))#"/prscsx_META_effect_1e-06.txt"

score_mcps<-c()
snps_used<-c()
for (chrom in 1:22){
  data_in<-fread(paste(working_directory,"/score_",chrom,"_",input_pop[i],".sscore",sep=""))
  snps_in<-fread(paste(working_directory,"/score_",chrom,"_",input_pop[i],".sscore.vars",sep=""),header=F)
  data_save<-data_in[,c(1,2,6)]
  colnames(data_save)[1:3]<-c("FID","IID",paste("score_chrom",chrom,sep=""))
  if(chrom==1){
    score_mcps<-data_save
    snps_used<-snps_in
  }else{
    score_mcps<-left_join(score_mcps,data_save,by=c("FID","IID"))
    snps_used<-rbind(snps_used,snps_in)
  }
}

colnames(snps_used)<-"snps"
sum(snps_used$snps%in%score_file$chr_pos)==nrow(score_file)#check if all snos are used

cat("\nAll snps selected from PRS-CSx were used:",sum(snps_used$snps%in%score_file$chr_pos)==nrow(score_file))
#sum across all chromosomes-----------------------------------------
score_mcps$score_sum<-rowSums(score_mcps[,3:24])
score_mcps$prs_standardised<-(score_mcps$score_sum-mean(score_mcps$score_sum))/sd(score_mcps$score_sum)
#hist(score_mcps$prs_standardised,prob = TRUE)
# #lines(density((score_mcps$prs_standardised)),
#       lwd = 2,
#       col = "chocolate3")

saveRDS(score_mcps,paste(working_directory,"/scoresum_standardised_",input_pop[i],"_",phi,".rds",sep=""))#META_1e-06
}
