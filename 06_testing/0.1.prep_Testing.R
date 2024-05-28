rm(list=ls())

#set working directory and readin data--------------------------------------
library(dplyr)
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training"
setwd(working_directory)
internal_validation_path<-paste(working_directory,"/Testing_data",sep="")
data<-readRDS(paste(internal_validation_path,"/Testing_data_CAD_EPA_80.rds",sep=""))

table(data$CAD_EPA)
prop.table(table(data$CAD_EPA))

outcome<-"CAD_EPA"
test_GWAS<-data
test_GWAS[,outcome]<-as.integer(test_GWAS[,outcome])
case_df_test<-test_GWAS[test_GWAS[,outcome]==1,c("FID","IID")]
pheno_df_test<-test_GWAS[,c("FID","IID",outcome)]
covar_df_test<-test_GWAS[c("FID","IID",c("SEX","AGE",paste("PC",1:7,sep="")))]
write.table(x=test_GWAS,file=paste(internal_validation_path,"/table_testing","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=case_df_test,file=paste(internal_validation_path,"/cases_testing","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=F)
write.table(x=pheno_df_test,file=paste(internal_validation_path, "/pheno_testing","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=covar_df_test,file=paste(internal_validation_path, "/covar_testing","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)

saveRDS(test_GWAS,paste(internal_validation_path,"/gwas_data.rds",sep=""))




