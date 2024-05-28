# 
rm(list=ls())
library(data.table)
library(dplyr)


ref<-c("A","C","T","G")

#--------------------------------------
data_hm3<-fread("/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/LD_reference/hm3_original/snpinfo_mult_1kg_hm3")
data_hm3_rm<-data_hm3[!data_hm3$A1%in%ref|!data_hm3$A2%in%ref,]
data_hm3_keep<-data_hm3[data_hm3$A1%in%ref&data_hm3$A2%in%ref,]
write.table(data_hm3_keep,"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/LD_reference/snpinfo_mult_1kg_hm3",quote = F,col.names = T,row.names = F,sep="\t")









