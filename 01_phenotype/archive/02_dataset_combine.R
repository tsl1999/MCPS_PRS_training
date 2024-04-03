##Rscript 02_dataset_combine.R working_directory pheno_folder
#this file is to prepare dataset for analysis
rm(list=ls())
library(dplyr)
arg = commandArgs(trailingOnly=TRUE)# arguments

#set working directory load package-----------------
working_path<-arg[1]
phenotype_path<-paste(working_path,"/",arg[2],sep="")
mcps_data_path<-"/well/emberson/projects/mcps/data/phenotypes/"
setwd(working_path)

library(data.table)
library(tidyr)
library(dplyr)
library(tidyverse)
"%&%" <- function(a,b) paste0(a,b)
#data readin------------------------------------------

phenotype<-data.frame(fread(paste(phenotype_path, '/extracted-phenotypes.txt',sep=''), header=T,dec =".",fill=T))

phenotype_na_rm<-phenotype[is.na(phenotype$IID)!=T&is.na(phenotype$PC1)!=T,]#140,829, included PC here

#data preprocess for GWAS---------------------------------

## unverified mortality------------------------------------
Mortality<-data.frame(fread(paste(mcps_data_path,"v2.1_DEATHS.csv",sep = "")))
mortality<-Mortality[!Mortality$grade%in%c("D","E","F","U","Z"),]
mortality_remove<-Mortality[Mortality$grade%in%c("D","E","F","U","Z"),]
table(mortality$grade,exclude=NULL)
table(mortality_remove$grade)
reg_link<-data.frame(fread(paste(mcps_data_path,"RGN_LINK_IID.csv",sep = "")))
mortality_keep<-merge(mortality[,c(1,3,13)],reg_link[,c(1,3)], by="REGISTRO")
mortality_remove<-left_join(mortality_remove[,c(1,3,13)],reg_link[,c(1,3)], by="REGISTRO")

data<-left_join(phenotype_na_rm,mortality_keep,by="IID")
data<-data[!data$IID%in%mortality_remove$IID,]#138611
table(data$grade,exclude=NULL)#all deaths under grade C removed

#-remove age over 75-----------------------------------------
data_rm_age75<-data[data$AGE<75,]#128387


data_rm_age75$date_since_recruitment<-as.Date("2020-12-31","%Y-%m-%d")-as.Date(data_rm_age75$DATE_RECRUITED,"%d%b%Y")
data_rm_age75$yr_since_recruitment<-as.numeric(data_rm_age75$date_since_recruitment)/365.25
data_rm_age75$yrs_died_recruitment<-(as.Date(data_rm_age75$DATE_OF_DEATH,"%d/%m/%Y")-as.Date(data_rm_age75$DATE_RECRUITED,"%d%b%Y"))/365.25

data_rm_age75$AGE_followup<-ifelse(is.na(data_rm_age75$yrs_died_recruitment)==F,round(data_rm_age75$AGE+data_rm_age75$yrs_died_recruitment,4),ifelse(
  is.na(data_rm_age75$yrs_died_recruitment)==T, round(data_rm_age75$AGE+data_rm_age75$yr_since_recruitment,4),NA
))

##combine baseline and mortality CAD cases-----------------------------
data_rm_age75$prevalent_CAD_EPA001<-ifelse(data_rm_age75$BASE_CHD==1,1,ifelse(
  is.na(data_rm_age75$EPA001)!=T&data_rm_age75$EPA001==1,1,0
))
table(data_rm_age75$prevalent_CAD_EPA001)

data_rm_age75$prevalent_CAD_EPO001<-ifelse(data_rm_age75$BASE_CHD==1,1,ifelse(
  is.na(data_rm_age75$EPO001)!=T&data_rm_age75$EPO001==1,1,0
))
table(data_rm_age75$prevalent_CAD_EPO001)


##death after 75 recoded-------------------------------------------------
data_update<-data_rm_age75
data_update$prevalent_CAD_EPA001_up<-ifelse(data_update$AGE_followup<75&data_update$prevalent_CAD_EPA001==1,1,0)
table(data_update$prevalent_CAD_EPA001_up)


data_update$prevalent_CAD_EPO001_up<-ifelse(data_update$AGE_followup<75&data_update$prevalent_CAD_EPO001==1,1,0)
table(data_update$prevalent_CAD_EPO001_up==1)


# data save------------------------------------------------------------
saveRDS(data_update,paste(phenotype_path,"/Fulldata_25Jan2024.rds",sep=""))

data_GWAS<-data_update[,c("FID","IID","SEX","AGE","prevalent_CAD_EPA001_up",
                          "prevalent_CAD_EPO001_up",paste("PC",1:7,sep=""))]

colnames(data_GWAS)[5:6]<-c("CAD_EPA","CAD_EPO")
data_GWAS$CAD_EPA<-as.integer(data_GWAS$CAD_EPA)
data_GWAS$CAD_EPO<-as.integer(data_GWAS$CAD_EPO)
case_df_EPA<-data_GWAS[data_GWAS$CAD_EPA==1,c("FID","IID")]
case_df_EPO<-data_GWAS[data_GWAS$CAD_EPO==1,c("FID","IID")]
pheno_df_EPA<-data_GWAS[,c("FID","IID","CAD_EPA")]
pheno_df_EPO<-data_GWAS[,c("FID","IID","CAD_EPO")]
covar_df<-data_GWAS[,c("FID","IID","SEX","AGE",paste("PC",1:7,sep=""))]


write.table(x=data_GWAS,file=phenotype_path %&% "/table_CAD.txt",
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=case_df_EPA,file=phenotype_path  %&% "/cases_CAD_EPA.txt",
            sep="\t",quote=F,row.names=F,col.names=F)
write.table(x=case_df_EPO,file=phenotype_path  %&% "/cases_CAD_EPO.txt",
            sep="\t",quote=F,row.names=F,col.names=F)
write.table(x=pheno_df_EPA,file=phenotype_path  %&% "/pheno_CAD_EPA.txt",
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=pheno_df_EPO,file=phenotype_path  %&% "/pheno_CAD_EPO.txt",
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=covar_df,file=phenotype_path  %&% "/covar_CAD.txt",
            sep="\t",quote=F,row.names=F,col.names=T)




