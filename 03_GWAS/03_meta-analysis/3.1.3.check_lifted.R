rm(list=ls())

#set working directory and readin data--------------------------------------
library(dplyr)
library(data.table)
path<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
cc4d<-fread(paste(path,"/cc4d_1KG_additive_2015_METAL_input.txt",sep=""))
bbj<-fread(paste(path,"/BBJCAD_2020_METAL_input.txt",sep=""))
UKB<-fread(paste(path,"/CAD_UKBIOBANK_METAL_input.txt",sep=""))


cc4d_unlifted<-fread(paste(path,"/cc4d_1KG_additive_2015_unlifted_up.bed",sep=""))
bbj_unlifted<-fread(paste(path,"/BBJCAD_2020_unlifted_up.bed",sep=""))
UKB_unlifted<-fread(paste(path,"/CAD_UKBIOBANK_unlifted_up.bed",sep=""))

duplicate_cc4d<-cc4d[cc4d$marker%in%cc4d$marker[duplicated(cc4d$marker)]]

duplicate_UKB<-UKB[UKB$marker%in%UKB$marker[duplicated(UKB$marker)]]
duplicate_bbj<-bbj[bbj$marker%in%bbj$marker[duplicated(bbj$marker)]]

bad_chrom_CC4D<-cc4d[cc4d$chromosome!=cc4d$CHR_ID,]
bad_chrom_BBJ<-bbj[bbj$chromosome!=bbj$CHR_ID,]
bad_chrom_UKB<-UKB[UKB$chromosome!=UKB$CHR_ID,]


saveRDS(duplicate_cc4d,paste(path,"/cc4d_gwas_duplicates.rds",sep=""))
saveRDS(duplicate_bbj,paste(path,"/bbj_gwas_duplicates.rds",sep=""))
saveRDS(duplicate_UKB,paste(path,"/ukb_gwas_duplicates.rds",sep=""))

saveRDS(bad_chrom_CC4D,paste(path,"/cc4d_gwas_bad_lifting.rds",sep=""))
saveRDS(bad_chrom_BBJ,paste(path,"/bbj_gwas_bad_lifting.rds",sep=""))
saveRDS(bad_chrom_UKB,paste(path,"/ukb_gwas_bad_lifting.rds",sep=""))

##check mcps duplicates

path_mcps<-"/well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_regenie/gwas_regenie_CAD_EPA_80/data_mcps_METAL_input.txt"
data_mcps<-fread(path_mcps)
duplicate_mcps<-data_mcps[data_mcps$marker%in%data_mcps$marker[duplicated(data_mcps$marker)]]




path_mcps<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie"
data_mcps2<-fread(paste(path_mcps,"/CAD_EPA_80_fulltraining/data_mcps_METAL_input.txt",sep=""))
duplicate_mcps2<-data_mcps2[data_mcps2$marker%in%data_mcps2$marker[duplicated(data_mcps2$marker)]]
saveRDS(duplicate_mcps2,paste(path_mcps,"/CAD_EPA_80_fulltraining/duplicate_gwas_snps.rds",sep=""))



for (i in 1:10){
  data_mcpsi<-fread(paste(path_mcps,"/CAD_EPA_80_fold_",i,"/data_mcps_METAL_input.txt",sep=""))
  duplicate_mcpsi<-data_mcpsi[data_mcpsi$marker%in%data_mcpsi$marker[duplicated(data_mcpsi$marker)]]
  saveRDS(duplicate_mcpsi,paste(path_mcps,"/CAD_EPA_80_fold_",i,"/duplicate_gwas_snps.rds",sep=""))
}
