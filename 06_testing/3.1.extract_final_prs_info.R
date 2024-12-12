rm(list=ls())
library(data.table)
library(dplyr)

working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Testing_data"
source("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/05_CAD_analysis_cv/0.1.utils.R")

#p+t--------------------------------------------------------------------
data_score_r2<-fread(paste(working_directory,"/PRS/1.P+T/P_T_r20.9_p0.005.snp",sep=""))
data_score_p<-data_score_r2[data_score_r2$P<=0.005,]
#double check withP_T_r20.9_p0.005.prsice
#find their effect size

data_effect_size<-fread("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis/metal_ukb_cc4d_bbj1.txt")
snp_retain<-data_effect_size[data_effect_size$MarkerName%in%data_score_p$SNP,]

saveRDS(snp_retain,paste(working_directory,"/PRS/1.P+T/P_T_r20.9_p0.005_score_file.rds",sep=""))
write.table(snp_retain,paste(working_directory,"/PRS/1.P+T/P_T_r20.9_p0.005_score_file.txt",sep=""),quote = F,row.names = F)

data_score_r2<-fread(paste(working_directory,"/PRS/1.P+T/P_T_r20.975_p0.011.snp",sep=""))
data_score_p<-data_score_r2[data_score_r2$P<=0.011,]
snp_retain<-data_effect_size[data_effect_size$MarkerName%in%data_score_p$SNP,]

saveRDS(snp_retain,paste(working_directory,"/PRS/1.P+T/P_T_r20.975_p0.011_score_file.rds",sep=""))
write.table(snp_retain,paste(working_directory,"/PRS/1.P+T/P_T_r20.975_p0.011_score_file.txt",sep=""),quote = F,row.names = F)

#LDPred-------------------------------------------------------------------

ldpred_snps<-readRDS(paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/ldpred-grid-beta_meta-analysis.rds",sep=""))
ldpred_snps<-cbind(rownames(ldpred_snps),ldpred_snps)
colnames(ldpred_snps)[1]<-"SNP"
ldpred_snps_retain<-data.frame(ldpred_snps[,c("SNP","p_0.0505_h2_0.025_TRUE")])
gwas_in<-fread("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fulltraining/meta-analysis/metal_ukb_ckb_cc4d_bbj1.txt")
snp_retain<-gwas_in[gwas_in$MarkerName%in%ldpred_snps_retain$SNP,]
snp_retain<-merge(snp_retain,ldpred_snps_retain,by.x = "MarkerName",by.y = "SNP")

saveRDS(snp_retain,paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/ldpred_p_0.0505_h2_0.025_TRUE_score_file.rds",sep=""))
write.table(snp_retain,paste(working_directory,"/PRS/2.LDPred/metal_ukb_ckb_cc4d_bbj/ldpred_p_0.0505_h2_0.025_TRUE_score_file.txt",sep=""),quote = F,row.names = F)
#PRS-CSx-----------------------------------------------------------------------

prscsx_effect<-fread(paste(working_directory,"/PRS/3.PRS-CSx/mcps_eur_eas_1e-05/prscsx_META_effect_1e-05.txt",sep=""))


