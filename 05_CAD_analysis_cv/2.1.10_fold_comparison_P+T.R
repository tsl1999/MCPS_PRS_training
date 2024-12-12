rm(list=ls())
library(data.table)
library(dplyr)
#arg = commandArgs(trailingOnly=TRUE)
#model output readining in---------------------------------------------
results_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/1.P+T"
#fold=1
#gwas="metal_cc4d_bbj"
setwd(results_directory)
sink("model_AUC_comparison.log")
model_gwas_compare_partial<-c()
model_gwas_compare_full<-c()
for(gwas in c("cc4d_bbj","ukb_cc4d","ukb_cc4d_bbj","ukb_ckb","ukb_ckb_cc4d_bbj",
              "his_ukb_cc4d", "his_all", "his_ukb_ckb_cc4d_bbj","his_ukb_cc4d_bbj")){
model_compare_partial<-c()
model_compare_full<-c()
for(fold in 1:10){
working_directory<-paste("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/1.P+T/fold",fold,"/metal_",gwas,sep="")

partial<-readRDS(paste(working_directory,"/logistic_model_output_partial.rds",sep=""))
full<-readRDS(paste(working_directory,"/logistic_model_output_full.rds",sep=""))

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

#plot(model_compare_full$meanAUC,type="p",ylim=c(0.759,0.761))
#plot(model_compare_partial$meanAUC,type="p",ylim=c(0.729,0.731))
cat("\nparameter with the highest auc in partial model of gwas ",gwas,"is ",
    model_compare_partial[1,1],"with AUC: ",model_compare_partial[1,"meanAUC"])
cat("\nparameter with the highest auc in full model of gwas ",gwas,"is",
    model_compare_full[1,1],"with AUC: ",model_compare_full[1,"meanAUC"])

saveRDS(model_compare_partial,paste(results_directory,"/model_compare_partial_",gwas,".rds",sep=""))
saveRDS(model_compare_full,paste(results_directory,"/model_compare_full_",gwas,".rds",sep=""))
final_compare_partial<-model_compare_partial%>%select(parameter,meanAUC)
colnames(final_compare_partial)[2]<-paste(colnames(final_compare_partial)[2],gwas,sep="_")

final_compare_full<-model_compare_full%>%select(parameter,meanAUC)
colnames(final_compare_full)[2]<-paste(colnames(final_compare_full)[2],gwas,sep="_")


if(which(gwas==c("cc4d_bbj","ukb_cc4d","ukb_cc4d_bbj","ukb_ckb","ukb_ckb_cc4d_bbj",
                 "his_ukb_cc4d", "his_all", "his_ukb_ckb_cc4d_bbj","his_ukb_cc4d_bbj"))==1){
  model_gwas_compare_partial<-final_compare_partial
  model_gwas_compare_full<-final_compare_full
}else{
  model_gwas_compare_partial<-left_join(model_gwas_compare_partial,final_compare_partial,by="parameter")
  model_gwas_compare_full<-left_join(model_gwas_compare_full,final_compare_full,by="parameter")
}


}
saveRDS( model_gwas_compare_partial,paste(results_directory,"/gwas_meanAUC_partial.rds",sep=""))
saveRDS( model_gwas_compare_full,paste(results_directory,"/gwas_meanAUC_full.rds",sep=""))

sink()
#all r2=0.9 and p=0.005 here



library(stringr)
library(ggplot2)
for(i in c("partial","full")){
  gwas_meanAUC<-readRDS(paste(results_directory,"/gwas_meanAUC_",i,".rds",sep=""))
  colnames(gwas_meanAUC)[2:9]<-sub("meanAUC_","",colnames(gwas_meanAUC)[2:9])
  gwas_meanAUC$r2 <- sub("r2_\\s*", "", str_extract(gwas_meanAUC$parameter, "r2_\\s*\\d+(\\.\\d+)?"))
  gwas_meanAUC$p<-sub("Pt_", "",str_extract(gwas_meanAUC$parameter, "Pt_\\d+\\.?\\d*e?_?\\d*"))
  gwas_meanAUC$p<-sub("e_", "e-",gwas_meanAUC$p)
  gwas_meanAUC$p<-sub("_", "",gwas_meanAUC$p)
  gwas_meanAUC$p<-as.numeric(gwas_meanAUC$p)
  gwas_meanAUC$r2<-as.factor(gwas_meanAUC$r2)
  dt_melt_standardised<-melt(gwas_meanAUC,c("p","r2","parameter"),value.name = "mean AUC")
  p<-ggplot(data = dt_melt_standardised, aes(x=p,y=`mean AUC`,color=r2)) + geom_line()+facet_wrap( ~ variable)+theme_bw()
  Cairo::CairoPNG(filename =paste(results_directory,"/gwas_meanAUC_compare_",i,".png",sep=""),res=200,width = 25,height = 15,units = "cm" )
  print(p)
  dev.off()




}










