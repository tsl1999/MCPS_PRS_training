rm(list=ls())

#set working directory and readin data--------------------------------------
library(dplyr)
library(data.table)
path<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
metal_out_path<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/03_GWAS/03_meta-analysis/out"
check_dropped<-data.frame(Name=NA,liftover=NA)
check_dropped[,3:12]<-NA
colnames(check_dropped)[3:12]<-paste("metal_fold",seq(1:10))

cc4d<-fread(paste(path,"/cc4d_1KG_additive_2015.txt",sep=""))
bbj<-fread(paste(path,"/BBJCAD_2020.txt",sep=""))
ukb<-fread(paste(path,"/CAD_UKBIOBANK.txt",sep=""))

sink(paste(metal_out_path,"/check_unlifted_meta-analysis_droppedSNPs.txt",sep=""))
cc4d_unlifted<-fread(paste(path,"/cc4d_1KG_additive_2015_unlifted_up.bed",sep=""))
bbj_unlifted<-fread(paste(path,"/BBJCAD_2020_unlifted_up.bed",sep=""))
ukb_unlifted<-fread(paste(path,"/CAD_UKBIOBANK_unlifted_up.bed",sep=""))
a<-c("cc4d","bbj","ukb")
for (i in 1:3){
  check_dropped[i,1]<-a[i]
  check_dropped[i,2]<-nrow(eval(as.name(paste(a[i],"unlifted",sep="_"))))/nrow(eval(as.name(a[i])))
}


b<-c("cc4d","BBJCAD","CAD_UKBIOBANK")
for (i in 1:10){
  metal_out<-readLines(paste(metal_out_path,"/fold",i,"_metal.out",sep=""))
  metal_out1<-metal_out[grepl(pattern = c("## Processed"), x = metal_out, fixed = TRUE)]
  metal_out2<-metal_out[grepl(pattern = c("## Processing"), x = metal_out, fixed = TRUE)]
  n<-sub(pattern = "## Processed ", replacement = "", x =  metal_out1, fixed = TRUE)
  n<-as.numeric(sub(pattern = " markers ...", replacement = "", x =  n, fixed = TRUE))
#cc4d
  for (j in 1:3){
    file<-sub("## Processing file '/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources/",
              "",x=metal_out2,fixed=T)
    file<-sub("_ucsc_meta-analysis_input.txt'","",x=file,fixed=T)
    
    cat("\n",a[j] ,"retained markers",n[which(file%flike%b[j])])
    
    check_dropped[j,i+2]<-1-(mean(n[which(file%flike%b[j])])/(nrow(eval(as.name(a[j])))-nrow(eval(as.name(paste(a[j],"unlifted",sep="_"))))))
  }
  

}
sink()
saveRDS(check_dropped,paste(metal_out_path,"/Dropped_snps.rds",sep=""))
