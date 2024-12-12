rm(list=ls())
library(data.table)
library(dplyr)
arg = commandArgs(trailingOnly=TRUE)
#FOR r2=0.2
working_directory<-arg[1]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/1.P+T/fold1/metal_cc4d_bbj"
pheno_directory<-arg[2]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/1"
data_in<-readRDS(paste(pheno_directory,"/validation_data_for_downstream_analysis.rds",sep=""))
model_output_all_partial<-c()
model_output_all_full<-c()
model_output_all_simple<-c()
cat("validation data from ",paste(pheno_directory,"/validation_data_for_downstream_analysis.rds",sep="") )
for (j in c(seq(0.2,0.9,by=0.1),1 )){
cat("reading P+T data from ",paste(working_directory,"/",j,".all_score",sep="") )  
data_score<-fread(paste(working_directory,"/",j,".all_score",sep=""))
prs_after_clump<-fread(paste(working_directory,"/",j,".snp",sep=""))


colnames(data_score)[3:ncol(data_score)]<-sub("-","_",colnames(data_score)[3:ncol(data_score)])

data_analysis<-merge(data_in,data_score,by=c("IID","FID"))
source("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/0.1.utils.R")

table(data_analysis$CAD_EPA)
cat("number of PRS input:",ncol(data_score)-2,"\n")

#data preparation---------------------------------------------------------------------
# data_analysis$SEX<-factor(data_analysis$SEX,levels = c(1,2),labels = c("Men","Women"))
# data_analysis$anti_diabetic<-rowSums(data_analysis%>%select(contains("DRUG")))
# data_analysis$anti_diabetic_medication<-ifelse(data_analysis$anti_diabetic>=1,1,0)
# data_analysis$anti_diabetic_medication<-factor(data_analysis$anti_diabetic_medication,levels=c(0,1))
# data_analysis$diabetic_lab<-ifelse(is.na(data_analysis$BASE_HBA1C)==F&data_analysis$BASE_HBA1C>=6.5,1,0)
# data_analysis$diabetic_lab<-factor(data_analysis$diabetic_lab,levels = c(0,1))
# data_analysis$diabetes_at_baseline<-ifelse(data_analysis$BASE_DIABETES==1|data_analysis$diabetic_lab==1|data_analysis$anti_diabetic_medication==1,1,0)
# data_analysis$diabetes_at_baseline<-factor(data_analysis$diabetes_at_baselin,levels=c(0,1))
# data_analysis$EDU_LEVEL<-factor(data_analysis$EDU_LEVEL,levels = c(1:4))
# data_analysis$smokegp2<-factor(data_analysis$smokegp2,levels = c(1:5))

table(data_analysis$diabetes_at_baseline)

#PRS prep---------------------------------------------------------------------------
prs_col<-which(colnames(data_analysis)%flike%"Pt_")
for (i in 1:(ncol(data_score)-2)){
  cat("PRS: ",colnames(data_analysis)[prs_col[i]])
  data_analysis[,paste(colnames(data_analysis)[prs_col[i]],"_standardised",sep="")]<-
    (data_analysis[,prs_col[i]]-mean(data_analysis[,prs_col[i]]))/sd(data_analysis[,prs_col[i]])
  }

data_analysis_up<-data_analysis%>%select(FID,IID,AGE,SEX,WHRATIO,SBP,DBP,EDU_LEVEL,
                                         smokegp2,diabetes_at_baseline,CAD_EPA,contains(c("standardised")))

#analysis--------------------------------------------------------------------------
partial_adjustments=c("AGE","SEX")
full_adjustments = c("AGE","SEX","WHRATIO","SBP","DBP","EDU_LEVEL","smokegp2","diabetes_at_baseline")

#no PRS
model_withoutPRS<-discrimination_without_prs(
  train_data = data_analysis_up,test_data = data_analysis,outcome="CAD_EPA",
  partial_adjustments = partial_adjustments,full_adjustments = full_adjustments)
print(model_withoutPRS)

#PRS----------------------------------------------------------------------------------
prs_p<-colnames(data_analysis_up)[which(colnames(data_analysis_up)%flike%"Pt_")]

model_output_partial<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=partial_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)
#model_output_partial<-model_output_partial[order(model_output_partial$AUC,decreasing = T),]
rownames(model_output_partial)<-paste("r2_",j,"_",rownames(model_output_partial))

cat("max AUC:",max(model_output_partial$AUC))
model_output_full<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=full_adjustments,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)

#model_output_full<-model_output_full[order(model_output_full$AUC,decreasing = T),]
cat("max AUC:",max(model_output_full$AUC))
rownames(model_output_full)<-paste("r2_",j,"_",rownames(model_output_full))

model_output_all_partial<-rbind(model_output_all_partial,model_output_partial)
model_output_all_full<-rbind(model_output_all_full,model_output_full)

model_output_simple<-create_output_table_log(
  trainsplit = F,data=data_analysis_up,adjustments=NULL,outcome="CAD_EPA",
  roc=F,se=T,prs = prs_p,dp=4)
#model_output_partial<-model_output_partial[order(model_output_partial$AUC,decreasing = T),]
rownames(model_output_simple)<-paste("r2_",j,"_",rownames(model_output_simple))

cat("max AUC:",max(model_output_simple$AUC))
model_output_all_simple<-rbind(model_output_all_simple,model_output_simple)
}

saveRDS(model_output_all_partial,paste(working_directory,"/logistic_model_output_partial.rds",sep=""))
saveRDS(model_output_all_full,paste(working_directory,"/logistic_model_output_full.rds",sep=""))
saveRDS(model_output_all_simple,paste(working_directory,"/logistic_model_output_simple.rds",sep=""))

# for(i in 1:10){
# 
# pheno_directory<-paste("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/",i,sep="")
# data_in<-readRDS(paste(pheno_directory,"/validation_data.rds",sep=""))
# 
# 
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
# 
# table(data_in$diabetes_at_baseline)
# print(table(data_in$CAD_EPA))
# saveRDS(data_in,paste(pheno_directory,"/validation_data_for_downstream_analysis.rds",sep=""))
# }
# 
