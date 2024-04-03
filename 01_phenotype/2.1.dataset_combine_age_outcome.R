##Rscript 02_dataset_combine.R working_directory pheno_folder
#this file is to prepare dataset for analysis
rm(list=ls())

arg = commandArgs(trailingOnly=TRUE)# arguments

#set working directory load package-----------------
working_path<-arg[1]
phenotype_path<-paste(working_path,"/",arg[2],sep="")
age_cut<-arg[3]
mcps_data_path<-"/well/emberson/projects/mcps/data/phenotypes/"
setwd(working_path)

library(data.table)
library(tidyr)
library(dplyr)
library(stats)

#data readin------------------------------------------

phenotype<-data.frame(fread(paste(phenotype_path, '/extracted-phenotypes.txt',sep=''), header=T,dec =".",fill=T))

phenotype_na_rm<-phenotype[is.na(phenotype$IID)!=T&is.na(phenotype$PC1)!=T&is.na(phenotype$SEX)!=T&is.na(phenotype$AGE)!=T,]#140,829, included PC here

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
data<-data[!data$IID%in%mortality_remove$IID,]#138609
print(nrow(data))
#-remove age over age_cut-----------------------------------------
data_rm_age_cut<-data[data$AGE<as.numeric(age_cut),]
print(nrow(data_rm_age_cut))

data_rm_age_cut$date_since_recruitment<-as.Date("2020-12-31","%Y-%m-%d")-as.Date(data_rm_age_cut$DATE_RECRUITED,"%d%b%Y")
data_rm_age_cut$yr_since_recruitment<-as.numeric(data_rm_age_cut$date_since_recruitment)/365.25
data_rm_age_cut$yrs_died_recruitment<-(as.Date(data_rm_age_cut$DATE_OF_DEATH,"%d/%m/%Y")-as.Date(data_rm_age_cut$DATE_RECRUITED,"%d%b%Y"))/365.25

data_rm_age_cut$AGE_followup<-ifelse(is.na(data_rm_age_cut$yrs_died_recruitment)==F,round(data_rm_age_cut$AGE+data_rm_age_cut$yrs_died_recruitment,4),ifelse(
  is.na(data_rm_age_cut$yrs_died_recruitment)==T, round(data_rm_age_cut$AGE+data_rm_age_cut$yr_since_recruitment,4),NA
))


##recode outcomes-----------------------------
## outcome that needs to be recoded after age cut
if(arg[4]!="NULL"){
  outcome_1<-strsplit(arg[4],split=",")[[1]]


for (i in 1:length(outcome_1)){
  data_rm_age_cut[,outcome_1[i]]<-ifelse(is.na(data_rm_age_cut[,outcome_1[i]])==T,0,data_rm_age_cut[,outcome_1[i]])
  data_rm_age_cut[,outcome_1[i]]<-ifelse(data_rm_age_cut$AGE_followup<as.numeric(age_cut)&data_rm_age_cut[,outcome_1[i]]==1,1,0)
}

}else{outcome_1<-NULL}





##outcomes don't need recode------------------------------------------------
if(arg[5]!="NULL"){
  outcome_2<-strsplit(arg[5],split=",")[[1]]
}else{outcome_2<-NULL}

##combine two types of outcomes---------------------------------------
data_update<-data_rm_age_cut

outcome_sum<-c(outcome_1,outcome_2)
if(length(outcome_sum)==1){
  data_update$outcome_combine<-data_update[,outcome_sum]
}else{
  data_update$outcome_combine<-rowSums(data_update[,c(outcome_1,outcome_2)])
}


data_update$outcome_combine_up<-ifelse(data_update$outcome_combine>=1,1,0)

table(data_update$outcome_combine_up,exclude=NULL)

#rename----------------------------------
outcome_name<-ifelse(is.null(arg[6])==T,"outcome",arg[6])
colnames(data_update)[which(colnames(data_update)=="outcome_combine_up")]<-outcome_name




# data save------------------------------------------------------------

saveRDS(data_update,paste(phenotype_path,"/Fulldata_",outcome_name,"_",age_cut,".rds",sep=""))


data_GWAS<-data_update[,c("FID","IID","SEX","AGE",outcome_name,paste("PC",1:7,sep=""))]

data_GWAS[,outcome_name]<-as.integer(data_GWAS[,outcome_name])
case_df<-data_GWAS[data_GWAS[,outcome_name]==1,c("FID","IID")]
pheno_df<-data_GWAS[,c("FID","IID",outcome_name)]

covar_df<-data_GWAS[,c("FID","IID","SEX","AGE",paste("PC",1:7,sep=""))]


write.table(x=data_GWAS,file= paste(phenotype_path,"/table_",outcome_name,"_",age_cut,".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)
write.table(x=case_df,file=paste(phenotype_path,"/cases_",outcome_name,"_",age_cut,".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=F)


write.table(x=pheno_df,file=paste(phenotype_path,"/pheno_",outcome_name,"_",age_cut,".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)

write.table(x=covar_df,file=paste(phenotype_path,"/covar_",outcome_name,"_",age_cut,".txt",sep=""),
            sep="\t",quote=F,row.names=F,col.names=T)


