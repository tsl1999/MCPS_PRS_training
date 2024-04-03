rm(list=ls())
library(data.table)
library(dplyr)
#set working directory and readin data--------------------------------------
# rtracklayer is more efficient, however its output will have more unlifted than UCSC genome brower and command line
# therefore I have changed to using command line liftover tool
arg = commandArgs(trailingOnly=TRUE)

if(arg[1]=="step1"){
working_directory<-arg[2]#"/well/emberson/users/hma817/projects/CAD_GWAS_whole/test/METAL/mcps_test"
setwd(working_directory)
data_in<-data.frame(fread(paste(arg[2],"/",arg[3],".txt",sep="")))

##column number of chr and pos
col_ids<-as.numeric(strsplit(arg[4],split=",")[[1]])

#colnames(data_in)[data_in[,col_ids[1]]]<-"CHR"
data_in$chromosome<-paste("chr",data_in[,col_ids[1]],sep="")
data_in$ID<-rownames(data_in)
colnames(data_in)[col_ids[c(1:8)]]<-c("chr","pos","effect_allele","non_effect_allele",
                                      "effect_allele_freq","beta","se","pval")
if(col_ids[9]!=-9){
  colnames(data_in)[col_ids[9]]<-"N"
}

data_in$OR<-exp(data_in$beta)
data_in$OR_95L<-exp(data_in$beta-1.96*data_in$se)
data_in$OR_95U<-exp(data_in$beta+1.96*data_in$se)

data_in$case<-col_ids[10]
data_in$control<-col_ids[11]
if(col_ids[9]!=-9){
  colnames(data_in)[col_ids[9]]<-"N"
}else{
  data_in$N<-data_in$case+data_in$control
}


if(is.na(col_ids[12])==T){
data_in$check<-data_in$case+data_in$control==data_in$N

    data_in$prop<-data_in$N/(data_in$case+data_in$control)
    data_in$case<-round(data_in$case*data_in$prop)
    data_in$control<-round(data_in$control*data_in$prop)
    data_in$N<-data_in$case+data_in$control
}else{
  #proportional to study
  max_study<-max(data_in[,col_ids[12]])
  data_in$check<-data_in[,col_ids[12]]==max_study

      data_in$prop<-data_in[,col_ids[12]]/max_study
      data_in$case<-round(data_in$case*data_in$prop)
      data_in$control<-round(data_in$control*data_in$prop)
}

cat("saving intermediate dataset.....")
saveRDS(data_in,paste(arg[2],"/",arg[3],"_data_for_step2_merge.rds",sep=""))

data_out<-data_in[,c(which(colnames(data_in)=="ID")-1,col_ids[2],col_ids[2],which(colnames(data_in)=="ID"))]

colnames(data_out)[1:4]<-c("CHR_ID","CHR_POS","CHR_POS_E","ID")
cat("\nsaving",paste(arg[3],"_updated.txt",sep=""),"...")
write.table(data_out,paste(arg[3],"_updated.txt",sep=""),col.names = F,row.names = F,quote=F)
}else if (arg[1]=="step2"){
  working_directory<-arg[2]
  setwd(working_directory)
  data_lifted<-fread(paste(arg[3],"_liftedhg38.bed",sep=""))#fread("/well/emberson/users/hma817/projects/CAD_GWAS_whole/test/METAL/mcps_test/output.bed")
  data_in<-readRDS(paste(arg[2],"/",arg[3],"_data_for_step2_merge.rds",sep=""))
  colnames(data_lifted)<-c("CHR_ID","position","CHR_POS_E","ID")
  data_lifted$ID<-as.character(data_lifted$ID)
  data_updated<-left_join(data_in,data_lifted[,c(1,2,4)],by="ID")
  data_updated$marker<-paste(data_updated$CHR_ID,":",data_updated$position,":",data_updated$effect_allele,":",data_updated$non_effect_allele,sep="")
  data_updated$marker_no_allele<-paste(data_updated$CHR_ID,":",data_updated$position,sep="")
  data_updated<-data_updated[is.na(data_updated$position)==F,]
  cat("\nsaving",paste(arg[2],"/",arg[3],"_meta-analysis_input.txt",sep=""),"...")
  if(is.na(arg[4])==F){
    write.table(data_updated,paste(arg[2],"/",arg[3],"_",arg[4],"_meta-analysis_input.txt",sep=""),col.names = T,row.names = F,quote=F)
  }else{
    write.table(data_updated,paste(arg[2],"/",arg[3],"_meta-analysis_input.txt",sep=""),col.names = T,row.names = F,quote=F)
  }

  
}



# data_mcps<-fread("/well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_regenie/gwas_regenie_CAD_EPA_80/output_files/combined-gwas-results.txt.gz")
# data_mcps$markername<-paste("chr",data_mcps$CHROM,":",data_mcps$GENPOS,sep="")
# write.table(data_mcps,"mcps.txt",col.names = T,row.names = F,quote=F)
# 
# 
 # data<-fread("/well/emberson/users/hma817/projects/CAD_GWAS_whole/test/METAL/mcps_test/mcps.txt")
 # data1_dup<-data[data$markername%in%data$markername[duplicated(data$markername)],]
 # data2<-fread("/well/emberson/users/hma817/projects/CAD_GWAS_whole/test/METAL/mcps_test/cc4d_updated_METAL.txt")
 # data2_dup<-data2[data2$marker%in%data2$marker[duplicated(data2$marker)],]