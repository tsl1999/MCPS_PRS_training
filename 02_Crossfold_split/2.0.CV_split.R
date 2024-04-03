rm(list=ls())

#set working directory and readin data--------------------------------------
library(dplyr)
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training"
setwd(working_directory)
source("/well/emberson/users/hma817/projects/MCPS_PRS_training/0.1utils.R")

data_path<-paste(working_directory,"/Training_data",sep="")
data<-readRDS(paste(data_path,"/Fulldata_training_CAD_EPA_80.rds",sep=""))
cvdata_path<-paste(data_path,"/crossfold",sep="")


#sort data EPA------------------------------------------
data_keep<-data%>%select(FID,IID,SEX,AGE,CAD_EPA,paste("PC",1:7,sep=""))
#colnames(data_keep)[5]<-c("CAD_EPA")
sum(data_keep$CAD_EPA)
#programme for splitting into training and validation------------------------------
data_out<-cross_validation_split(data_keep = data_keep,fold=10,outcome="CAD_EPA",
                                 seed=1000,save=T,data_path = cvdata_path,
                                 covar=c("SEX","AGE",paste("PC",1:7,sep="")),gwas=T,full_data = data)

cv_split<-data_out[[1]]
cv_split_prop<-data_out[[2]]

saveRDS(cv_split,paste(cvdata_path,"/CAD_EPA/fullcvdataEPA_28Mar2024.rds",sep=""))
saveRDS(cv_split_prop,paste(cvdata_path,"/CAD_EPA/fullcvdata_train_validation_proprtionEPA_28Mar2024.rds",sep=""))

##check whether all IDs are included in validation--------------------------------
check_ID<-c()
for(i in 1:10){check_ID<-c(check_ID,cv_split[[i]]$vallidation$IID)}
length(unique(check_ID))
sum(!check_ID%in%data$IID)
sum(data$IID%in%check_ID)
