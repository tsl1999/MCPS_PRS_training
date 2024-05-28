rm(list=ls())
library(data.table)
library(dplyr)
arg = commandArgs(trailingOnly=TRUE)
#test folder
working_directory<-arg[1]#"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/3.PRS-CSx/test"
setwd(working_directory)

data_com_meta<-c()
pop_in<-strsplit(arg[2],split=",")[[1]]#c("AMR","EAS")
data_pop<-list()
global_phi<-arg[3]#1e-06
# cat("reading meta-analysed posterior effect...")
# for (i in 1:22){
#   data_in<-fread(paste("prscsx_META_pst_eff_a1_b0.5_phi",global_phi,"_chr",i,".txt",sep=""))
#   data_com_meta<-rbind(data_com_meta,data_in)
# }

for(i in 1:length(pop_in)){
  cat("\n reading posterior effect of ", pop_in[i])
  data_inter<-c()
  for(j in 1:22){
    if(global_phi=="1"){
      phi="1e+00"
    }else{
      phi=global_phi
    }
    data_in<-fread(paste("prscsx_",pop_in[i],"_pst_eff_a1_b0.5_phi",phi,"_chr",j,".txt",sep=""))
    data_inter<-rbind(data_inter,data_in)
  }
  data_pop[[i]]<-data_inter
  names(data_pop)[i]<-pop_in[i]
}




#rsid to chromosome id for meta file-----------------------------------------------------------
rsid_conversion_list <- readRDS("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_rsid_list.rds")
ref_list<-rsid_conversion_list%>%select(rsid,chr_pos,A1,A2)


# colnames(data_com_meta)<-c("chr","rsid", "pos", "A1", "A2" ,"posterior_effect")
# data_left_join<-left_join(data_com_meta,ref_list,by=c("rsid","A1","A2"))
# 
# data_save<-data_left_join%>%select(chr_pos,rsid,A1,A2,posterior_effect)
# #sum(is.na(data_save$posterior_effect)) #check is there is NA
# cat("\nsaving meta-analysed posterior effect...")
# write.table(data_save,paste("prscsx_META_effect_",global_phi,".txt",sep=""),quote=F,row.names = F,col.names = T,sep="\t")
#rsid to chromosome id for pop-specific file---------------------------------------------------
for(i in 1:length(pop_in)){
  cat("\npopulation ",pop_in[i])
  data_in<-data_pop[[pop_in[i]]]
  colnames(data_in)<-c("chr","rsid", "pos", "A1", "A2" ,"posterior_effect")
  data_pop_left_join<-left_join(data_in,ref_list,by=c("rsid","A1","A2"))
  data_pop_save<-data_pop_left_join%>%select(chr_pos,rsid,A1,A2,posterior_effect)
  #sum(is.na(data_pop_save$posterior_effect))
  cat("\nsaving posterior effect for population", pop_in[i])
  write.table(data_pop_save,paste("prscsx_",pop_in[i],"_effect_",global_phi,".txt",sep=""),quote=F,row.names = F,col.names = T,sep="\t")
}




