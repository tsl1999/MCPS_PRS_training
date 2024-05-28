rm(list=ls())

#set working directory and readin data--------------------------------------
library(dplyr)
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training"
setwd(working_directory)
dir.create(paste(working_directory,"/Testing_data",sep=""))
dir.create(paste(working_directory,"/Training_data",sep=""))
internal_validation_path<-paste(working_directory,"/Testing_data",sep="")
Training_testing_path<-paste(working_directory,"/Training_data",sep="")
data_path<-paste(working_directory,"/data",sep="")
data<-readRDS(paste(data_path,"/Fulldata_CAD_EPA_80.rds",sep=""))


#sample-out for internal evaluation-----------------------------------
set.seed(1000)
percent_out=0.2
percent_keep=0.8
number_out<-round(nrow(data)*percent_out)
out_ID<-sample(data$IID,size=number_out,replace = F)#keep out for all training and tuning
keep_ID<-data$IID[!data$IID%in%out_ID]

length(unique(c(out_ID,keep_ID)))

out<-data[data$IID%in%out_ID,]
prop.table(table(out$CAD_EPA))#%3.773%

saveRDS(out,paste(internal_validation_path,"/Testing_data_CAD_EPA_80.rds",sep=""))

keep<-data[data$IID%in%keep_ID,]
prop.table(table(keep$CAD_EPA))#3.648%

saveRDS(keep,paste(Training_testing_path,"/Fulldata_training_CAD_EPA_80.rds",sep=""))



#make GWAS file of the training set---------------------------------------


data<-readRDS(paste(Training_testing_path,"/Fulldata_training_CAD_EPA_80.rds",sep=""))
table(data$CAD_EPA)
prop.table(table(data$CAD_EPA))

outcome<-"CAD_EPA"
train_GWAS<-data
train_GWAS[,outcome]<-as.integer(train_GWAS[,outcome])
case_df_train<-train_GWAS[train_GWAS[,outcome]==1,c("FID","IID")]
pheno_df_train<-train_GWAS[,c("FID","IID",outcome)]
covar_df_train<-train_GWAS[c("FID","IID",c("SEX","AGE",paste("PC",1:7,sep="")))]
write.table(x=train_GWAS,file=paste(Training_testing_path,"/table_training","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=case_df_train,file=paste(Training_testing_path,"/cases_training","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=F)
write.table(x=pheno_df_train,file=paste(Training_testing_path, "/pheno_training","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=covar_df_train,file=paste(Training_testing_path, "/covar_training","_","CAD_EPA_80",".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)

saveRDS(train_GWAS,paste(Training_testing_path,"/gwas_data.rds",sep=""))




