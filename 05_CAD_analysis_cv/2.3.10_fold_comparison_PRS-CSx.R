rm(list=ls())
library(data.table)
library(dplyr)
#model output readining in---------------------------------------------
results_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/3.PRS-CSx"

setwd(results_directory)
sink("model_AUC_comparison.log")
model_gwas_compare_partial<-c()
model_gwas_compare_full<-c()
for(fold in 1:10){
  working_directory<-paste("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/3.PRS-CSx/fold",fold,sep="")
  
  partial<-readRDS(paste(working_directory,"/logistic_model_output_partial_auc.rds",sep=""))
  full<-readRDS(paste(working_directory,"/logistic_model_output_full_auc.rds",sep=""))
  
  partial_auc<-partial%>%select(AUC)
  partial_auc$AUC<-as.numeric(partial_auc$AUC)
  partial_auc$parameter<-rownames(partial_auc)
  colnames(partial_auc)[1]<-paste("AUC",fold,sep="")
  partial_auc<-partial_auc[,c(2,1)]
  full_auc<-full%>%select(AUC)
  full_auc$AUC<-as.numeric(full_auc$AUC)
  colnames(full_auc)[1]<-paste("AUC",fold,sep="")
  full_auc$parameter<-rownames(full_auc)
  full_auc<-full_auc[,c(2,1)]
  
  if(fold==1){
    model_compare_partial<-partial_auc
    model_compare_full<-full_auc
  }else{
    
  
    model_compare_partial<-left_join(model_compare_partial,partial_auc,by="parameter")
    model_compare_full<-left_join(model_compare_full,full_auc,by="parameter")
  }
  
  
}


rownames(model_compare_partial)<-model_compare_partial$parameter
rownames(model_compare_full)<-model_compare_full$parameter
model_compare_partial$meanAUC<-rowMeans(model_compare_partial[,2:11])
model_compare_full$meanAUC<-rowMeans(model_compare_full[,2:11])
model_compare_partial<-model_compare_partial[order(model_compare_partial$meanAUC,decreasing = T),]
model_compare_full<-model_compare_full[order(model_compare_full$meanAUC,decreasing = T),]
cat("\nparameter with the highest auc in partial model is ",
    model_compare_partial[1,1],"with AUC: ",model_compare_partial[1,"meanAUC"] )
cat("\nparameter with the highest auc in full model of gwas is",
    model_compare_full[1,1],"with AUC: ",model_compare_full[1,"meanAUC"])
saveRDS(model_compare_partial,paste(results_directory,"/model_compare_partial.rds",sep=""))
saveRDS(model_compare_full,paste(results_directory,"/model_compare_full.rds",sep=""))

sink()

