rm(list=ls())
library(data.table)
library(dplyr)
library(tidyr)
arg = commandArgs(trailingOnly=TRUE)
pop_in<-strsplit(arg[1],split = ":")[[1]]#c("META,AMR,EAS:META,AMR,EUR:META,AMR,EAS,EUR")

phi<-strsplit(arg[3],split = ",")[[1]]#1e-06,1e-04,1e-02,1
gwas<-strsplit(arg[2],split = ",")[[1]]#mcps_bbj,mcps_ukb,mcps_bbj_ukb
working_directory<-arg[4]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/3.PRS-CSx/fold1"
pheno_directory<-arg[5]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/1"
data_in<-readRDS(paste(pheno_directory,"/validation_data_for_downstream_analysis.rds",sep=""))


#call in all PRSes from one fold----------------------------------------------------------------
prs_combine_phi_gwas<-c()
prs_combine_phi_gwas_list<-list()
for(i in 1:length(gwas)){
  population_in<-strsplit(pop_in[i],split = ",")[[1]]
  prs_combine_phi<-c()
  for(j in 1:length(phi)){
data_directory<-paste(working_directory,"/",gwas[i],"_",phi[j],sep="")

data_prs<-c()

for(k in 1:length(population_in)){
  prs<-readRDS(paste(data_directory,"/scoresum_standardised_",population_in[k],"_",phi[j],".rds",sep=""))
  prs_save<-prs%>%select(FID,IID,prs_standardised)
  colnames(prs_save)[3]<-paste("prs",gwas[i],phi[j],population_in[k],sep="_")
  colnames(prs_save)[3]<-sub("-","_",colnames(prs_save)[3])
  if(k==1){
    data_prs<-prs_save
  }else{
    data_prs<-left_join(data_prs,prs_save,by=c("IID","FID"))
  }
  
}
prs_combine_phi_gwas_list[[length(prs_combine_phi_gwas_list)+1]]<-colnames(data_prs)[!colnames(data_prs) %flike% "META"][-c(1:2)]

names(prs_combine_phi_gwas_list)[length(prs_combine_phi_gwas_list)]<-paste(gwas[i],phi[j],sep="_")

 if(j==1){
   prs_combine_phi<-data_prs
  
 }else{
   prs_combine_phi<-left_join(prs_combine_phi,data_prs,by=c("IID","FID"))
 }
}
  if(i==1){
    prs_combine_phi_gwas<-prs_combine_phi
  }else{
    prs_combine_phi_gwas<-left_join(prs_combine_phi_gwas,prs_combine_phi,by=c("IID","FID"))
  }
  
  }

#analysis----------------------------------------------------------------------------------------------
data_analysis<-left_join(data_in,prs_combine_phi_gwas,by=c("IID","FID"))
data_analysis_up<-data_analysis%>%select(FID,IID,AGE,SEX,WHRATIO,SBP,DBP,EDU_LEVEL,
                                         smokegp2,diabetes_at_baseline,CAD_EPA,contains(c("META")))

source("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/0.1.utils.R")

partial_adjustments=c("AGE","SEX")
full_adjustments = c("AGE","SEX","WHRATIO","SBP","DBP","EDU_LEVEL","smokegp2","diabetes_at_baseline")

#no PRS
model_withoutPRS<-discrimination_without_prs(
  train_data = data_analysis_up,test_data = data_analysis,outcome="CAD_EPA",
  partial_adjustments = partial_adjustments,full_adjustments = full_adjustments)
print(model_withoutPRS)


#single PRS analysis----------------------------------------------------------------------------------
prs_p<-colnames(data_analysis_up)[which(colnames(data_analysis_up)%flike%"prs_")]

model_output_partial<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=partial_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)

meta_model_output_partial<-model_output_partial[order(model_output_partial$AUC,decreasing = T),]


#cat("max AUC:",max(model_output_partial$AUC))
model_output_full<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=full_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)

meta_model_output_full<-model_output_full[order(model_output_full$AUC,decreasing = T),]
#cat("max AUC:",max(model_output_full$AUC))

#linear combination--------------------------------------------------------------------

model_output_partial<-create_output_table_log_multi(trainsplit=F,data=data_analysis,
                                                adjustments=partial_adjustments,
                                                outcome="CAD_EPA",int=NULL,
                                                prs=prs_combine_phi_gwas_list,dp=4)

auc_partial<-model_output_partial$model_auc
meta_auc_partial<-meta_model_output_partial[,c(colnames(auc_partial))]
auc_partial_all<-rbind(auc_partial,meta_auc_partial)
auc_partial_all<-auc_partial_all[order(auc_partial_all$AUC,decreasing = T),]
or_partial<-model_output_partial$odds_ratio
or_partial_meta<-meta_model_output_partial[,c(colnames(or_partial[[1]]))]
or_partial_all<-or_partial
or_partial_all[[length(or_partial_all)+1]]<-or_partial_meta
names(or_partial_all)[length(or_partial_all)]<-"meta_or"

cat("max AUC:",max(auc_partial_all$AUC))
saveRDS(auc_partial_all,paste(working_directory,"/logistic_model_output_partial_auc.rds",sep=""))
saveRDS(or_partial_all,paste(working_directory,"/logistic_model_output_partial_OR.rds",sep=""))

model_output_full<-create_output_table_log_multi(trainsplit=F,data=data_analysis,
                                             adjustments=full_adjustments,
                                             outcome="CAD_EPA",int=NULL,
                                             prs=prs_combine_phi_gwas_list,dp=4)

auc_full<-model_output_full$model_auc
meta_auc_full<-meta_model_output_full[,c(colnames(auc_full))]
auc_full_all<-rbind(auc_full,meta_auc_full)
auc_full_all<-auc_full_all[order(auc_full_all$AUC,decreasing = T),]
or_full<-model_output_full$odds_ratio
or_full_meta<-meta_model_output_full[,c(colnames(or_full[[1]]))]
or_full_all<-or_full
or_full_all[[length(or_full_all)+1]]<-or_full_meta
names(or_full_all)[length(or_full_all)]<-"meta_or"

cat("max AUC:",max(auc_full_all$AUC))
saveRDS(auc_full_all,paste(working_directory,"/logistic_model_output_full_auc.rds",sep=""))
saveRDS(or_full_all,paste(working_directory,"/logistic_model_output_full_OR.rds",sep=""))












