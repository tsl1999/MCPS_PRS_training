rm(list=ls())
library(data.table)
library(dplyr)
library(tidyr)
arg = commandArgs(trailingOnly=TRUE)

working_directory<-arg[1]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/2.LDPred/fold1/metal_cc4d_bbj"
pheno_directory<-arg[2]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/1"
data_in<-readRDS(paste(pheno_directory,"/validation_data_for_downstream_analysis.rds",sep=""))
participants_order<-readRDS(paste(working_directory,"/participants_order_meta-analysis.rds",sep=""))
model_output_all_partial<-c()
model_output_all_full<-c()
print(table(data_in$CAD_EPA))

prs_inf_norm<-readRDS(paste(working_directory,"/ldpred-inf-pred_norm.rds",sep=""))
prs_inf_meta<-readRDS(paste(working_directory,"/ldpred-inf-pred_meta-analysis.rds",sep=""))

data_in_grid_norm<-data.frame(readRDS(paste(working_directory,"/ldpred-grid-pred_norm.rds",sep="")))
colnames(data_in_grid_norm)<-sub("X","prs_gridnorm_",colnames(data_in_grid_norm))
data_in_grid_meta<-data.frame(readRDS(paste(working_directory,"/ldpred-grid-pred_meta-analysis.rds",sep="")))
colnames(data_in_grid_meta)<-sub("X","prs_gridmeta_",colnames(data_in_grid_meta))
data_in_grid_norm_na<-data_in_grid_norm[,!is.na(colSums(data_in_grid_norm))]
data_in_grid_meta_na<-data_in_grid_meta[,!is.na(colSums(data_in_grid_meta))]

prs<-data.frame(participants_order$family.ID,participants_order$sample.ID,prs_inf_norm,prs_inf_meta,data_in_grid_norm_na,data_in_grid_meta_na)
colnames(prs)[1:2]<-c("FID","IID")

#already standardised

data_analysis<-left_join(data_in,prs,by=c("IID","FID"))

#sum(is.na(data_analysis[,58:893]))
cat("number of PRS input:",ncol(prs)-2,"\n")

#analysis--------------------------------------------------------------------------
source("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/0.1.utils.R")
data_analysis_up<-data_analysis%>%select(FID,IID,AGE,SEX,WHRATIO,SBP,DBP,EDU_LEVEL,
                                         smokegp2,diabetes_at_baseline,CAD_EPA,contains(c("prs")))
partial_adjustments=c("AGE","SEX")
full_adjustments = c("AGE","SEX","WHRATIO","SBP","DBP","EDU_LEVEL","smokegp2","diabetes_at_baseline")

#no PRS
model_withoutPRS<-discrimination_without_prs(
  train_data = data_analysis_up,test_data = data_analysis,outcome="CAD_EPA",
  partial_adjustments = partial_adjustments,full_adjustments = full_adjustments)
print(model_withoutPRS)


#PRS----------------------------------------------------------------------------------
prs_p<-colnames(data_analysis_up)[which(colnames(data_analysis_up)%flike%"prs_")]

model_output_partial<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=partial_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)
model_output_partial<-model_output_partial[order(model_output_partial$AUC,decreasing = T),]


cat("max AUC:",max(model_output_partial$AUC))
model_output_full<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=full_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)

model_output_full<-model_output_full[order(model_output_full$AUC,decreasing = T),]
cat("max AUC:",max(model_output_full$AUC))

saveRDS(model_output_partial,paste(working_directory,"/logistic_model_output_partial.rds",sep=""))
saveRDS(model_output_full,paste(working_directory,"/logistic_model_output_full.rds",sep=""))



