rm(list=ls())

#set working directory and readin data--------------------------------------
suppressMessages(library(dplyr))

working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS"
setwd(working_directory)

pt_results<-readRDS(paste(working_directory,"/1.P+T/gwas_meanAUC_full.rds",sep=""))
ldpred_results<-readRDS(paste(working_directory,"/2.LDPred/gwas_meanAUC_full.rds",sep=""))
prscsx_results<-readRDS(paste(working_directory,"/3.PRS-CSx/model_compare_full.rds",sep=""))

max(pt_results[,2:10],na.rm = T)

which(pt_results[,2:10]==max(pt_results[,2:10],na.rm=T))
max_pt<-data.frame(name=NA,parameter=NA, AUC=NA)
for(i in 1:9){
  pt_results_col<-pt_results[,c(1,i+1)]
 # cat("\n the max AUC for P+T method",colnames(pt_results_col)[2], "is",max(pt_results_col[,2]), 
  #    "of parameter", pt_results_col[pt_results_col[,2]==max(pt_results_col[,2]),1])
  max_pt[i,]<-c(colnames(pt_results_col)[2],
               paste( pt_results_col[pt_results_col[,2]==max(pt_results_col[,2],na.rm=T),1],collapse="\n"),
                    max(pt_results_col[,2],na.rm=T))
}



max_ldpred<-data.frame(name=NA,parameter=NA, AUC=NA)
for(i in 1:9){
  ldpred_results_col<-ldpred_results[,c(1,i*2,i*2+1)]
  ld_retain<-ldpred_results_col[ldpred_results_col[,3]==0&is.na(ldpred_results_col[,3])==F,]
  #cat("\n the max AUC for LDPred method",colnames(ld_retain)[2], "is",max(ld_retain[,2]), 
  #    "of parameter", ld_retain[ld_retain[,2]==max(ld_retain[,2]),1])
  max_ldpred[i,]<-c(colnames(ld_retain)[2],
                    paste(ld_retain[ld_retain[,2]==max(ld_retain[,2]),1],collapse="\n"),
                    max(ld_retain[,2]))
}


cat("1. Pruning and Thresholding \n")
#print(max_pt)
print(max_pt[max_pt$AUC==max(max_pt$AUC),])

cat("2. LDPred \n")
#print(max_ldpred)
print(max_ldpred[max_ldpred$AUC==max(max_ldpred$AUC),])


max_prscsx<-c(prscsx_results[prscsx_results$meanAUC==max(prscsx_results$meanAUC),1],max(prscsx_results$meanAUC))
cat("3. PRS-CSx \n")
print(max_prscsx)
