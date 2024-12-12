rm(list=ls())
library(data.table)
library(dplyr)

working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Testing_data"
data_in<-readRDS(paste(working_directory,"/Testing_data_downstream.rds",sep=""))
source("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/0.1.utils.R")
#data preparation---------------------------------------------------------------------
# data_in$SEX<-factor(data_in$SEX,levels = c(1,2),labels = c("Men","Women"))
# data_in$anti_diabetic<-rowSums(data_in%>%select(contains("DRUG")))
# data_in$anti_diabetic_medication<-ifelse(data_in$anti_diabetic>=1,1,0)
# data_in$anti_diabetic_medication<-factor(data_in$anti_diabetic_medication,levels=c(0,1))
# data_in$diabetic_lab<-ifelse(is.na(data_in$BASE_HBA1C)==F&data_in$BASE_HBA1C>=6.5,1,0)
# data_in$diabetic_lab<-factor(data_in$diabetic_lab,levels = c(0,1))
# data_in$diabetes_at_baseline<-ifelse(data_in$BASE_DIABETES==1|data_in$diabetic_lab==1|data_in$anti_diabetic_medication==1,1,0)
# data_in$diabetes_at_baseline<-factor(data_in$diabetes_at_baselin,levels=c(0,1))
# data_in$EDU_LEVEL<-factor(data_in$EDU_LEVEL,levels = c(1:4))
# data_in$smokegp2<-factor(data_in$smokegp2,levels = c(1:5))
# saveRDS(data_in,paste(working_directory,"/Testing_data_downstream.rds",sep=""))

#p+t--------------------------------------------------------------------
data_score<-fread(paste(working_directory,"/PRS/1.P+T/P_T_r20.975_p0.011.all_score",sep=""))
data_analysis<-merge(data_in,data_score,by=c("IID","FID"))
table(data_analysis$CAD_EPA)
cat("number of PRS input:",ncol(data_score)-2,"\n")

prs_col<-which(colnames(data_analysis)%flike%"Pt_")
for (i in 1:(ncol(data_score)-2)){
  cat("PRS: ",colnames(data_analysis)[prs_col[i]])
  data_analysis[,paste(colnames(data_analysis)[prs_col[i]],"_standardised",sep="")]<-
    (data_analysis[,prs_col[i]]-mean(data_analysis[,prs_col[i]]))/sd(data_analysis[,prs_col[i]])
}
data_analysis_up<-data_analysis%>%select(FID,IID,AGE,SEX,WHRATIO,SBP,DBP,EDU_LEVEL,
                                         smokegp2,diabetes_at_baseline,CAD_EPA,contains(c("standardised")))

##analysis--------------------------------------------------------------------------
partial_adjustments=c("AGE","SEX")
full_adjustments = c("AGE","SEX","WHRATIO","SBP","DBP","EDU_LEVEL","smokegp2","diabetes_at_baseline")

#no PRS
model_withoutPRS<-discrimination_without_prs(
  train_data = data_analysis_up,test_data = data_analysis,outcome="CAD_EPA",
  partial_adjustments = partial_adjustments,full_adjustments = full_adjustments)
print(model_withoutPRS)

#LDPred--------------------------------------------------------------------
prs_inf_meta<-readRDS(paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/ldpred-inf-pred_meta-analysis.rds",sep=""))
prs_inf_meta_standardised<-(prs_inf_meta-mean(prs_inf_meta))/sd(prs_inf_meta)
data_in_grid_meta<-data.frame(readRDS(paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/ldpred-grid-pred_meta-analysis.rds",sep="")))
data_in_grid_meta_na<-data_in_grid_meta[,!is.na(colSums(data_in_grid_meta))]
participants_order<-readRDS(paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/participants_order_meta-analysis.rds",sep=""))
for (i in 1:(ncol(data_in_grid_meta_na))){
  cat("PRS: ",colnames(data_in_grid_meta_na)[i])
  data_in_grid_meta_na[,paste(colnames(data_in_grid_meta_na)[i],"_standardised",sep="")]<-
    (data_in_grid_meta_na[,i]-mean(data_in_grid_meta_na[,i]))/sd(data_in_grid_meta_na[,i])
}
prs<-data.frame(participants_order$family.ID,participants_order$sample.ID,prs_inf_meta_standardised,data_in_grid_meta_na)


colnames(prs)[1:2]<-c("FID","IID")
data_analysis_up<-merge(data_analysis_up,prs,by=c("IID","FID"))

#prs-csx-------------------------------------------------------------------------------
population_in<-c("AMR","EUR","EAS","META")
phi=1e-04
for(k in 1:length(population_in)){
  prs<-readRDS(paste(working_directory,"/PRS/3.PRS-CSx/mcps_eur_eas_1e-04/scoresum_standardised_",population_in[k],"_",phi,".rds",sep=""))
  prs_save<-prs%>%select(FID,IID,prs_standardised)
  colnames(prs_save)[3]<-paste("prs-csx",population_in[k],sep="_")
  colnames(prs_save)[3]<-sub("-","_",colnames(prs_save)[3])
  if(k==1){
    data_prs<-prs_save
  }else{
    data_prs<-left_join(data_prs,prs_save,by=c("IID","FID"))
  }
  
}

data_analysis_up<-merge(data_analysis_up,data_prs,by=c("IID","FID"))


##analysis--------------------------------------------------------------------


prs_combine<-list(colnames(data_prs)[!colnames(data_prs) %flike% "META"][-c(1:2)])
names(prs_combine)<-"mcps_eur_eas_1e-04"
model_output_simple_prscsx<-create_output_table_log_multi(trainsplit=F,data=data_analysis_up,
                                                           adjustments=c(),
                                                           outcome="CAD_EPA",int=NULL,
                                                           prs=prs_combine,dp=4)
model_output_partial_prscsx<-create_output_table_log_multi(trainsplit=F,data=data_analysis_up,
                                                    adjustments=partial_adjustments,
                                                    outcome="CAD_EPA",int=NULL,
                                                    prs=prs_combine,dp=4)
model_output_full_prscsx<-create_output_table_log_multi(trainsplit=F,data=data_analysis_up,
                                                    adjustments=full_adjustments,
                                                    outcome="CAD_EPA",int=NULL,
                                                    prs=prs_combine,dp=4)


#other prss-----------------------------------------------------

FullData_17Apr2024 <- readRDS("/gpfs3/well/emberson/users/hma817/projects/existing_PRS/correction/data/FullData_17Apr2024.rds")[,c(1,51:58)]
for(i in 2:9){
  FullData_17Apr2024[,i]<-(FullData_17Apr2024[,i]-mean(FullData_17Apr2024[,i]))/sd(FullData_17Apr2024[,i])
}
colnames(FullData_17Apr2024)[8]<-"custom_Oni_Orisan_standardised"
other_prs<-merge(data_analysis_up,FullData_17Apr2024,by="IID")

model_output_simple<-create_output_table_log(
  trainsplit = F,data=other_prs,adjustments=c(),outcome="CAD_EPA",
  roc=F,se=T,prs = c("PGS","custom","Pt_","standardised","prs"),dp=4)

model_output_partial<-create_output_table_log(
  trainsplit = F,data=other_prs,adjustments=partial_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = c("PGS","custom","Pt_","standardised","prs"),dp=4)

model_output_full<-create_output_table_log(
  trainsplit = F,data=other_prs,adjustments=full_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = c("PGS","custom","Pt_","standardised","prs"),dp=4)

all_simple<-rbind(model_output_simple[,4:10],model_output_simple_prscsx[[1]])
all_partial<-rbind(model_output_partial[,4:10],model_output_partial_prscsx[[1]])
all_full<-rbind(model_output_full[,4:10],model_output_full_prscsx[[1]])


saveRDS(all_simple,paste(working_directory,"/testing_model_simple.rds",sep=""))
saveRDS(all_partial,paste(working_directory,"/testing_model_partial.rds",sep=""))
saveRDS(all_full,paste(working_directory,"/testing_model_full.rds",sep=""))

saveRDS(model_output_simple,paste(working_directory,"/testing_model_simple_OR.rds",sep=""))
saveRDS(model_output_partial,paste(working_directory,"/testing_model_partial_OR.rds",sep=""))
saveRDS(model_output_full,paste(working_directory,"/testing_model_full_OR.rds",sep=""))

