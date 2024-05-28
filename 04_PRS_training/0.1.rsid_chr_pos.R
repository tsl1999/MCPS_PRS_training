rm(list=ls())
library(data.table)
library(dplyr)
# library(GenomicRanges)
# library(SNPlocs.Hsapiens.dbSNP155.GRCh38)
# snps<-SNPlocs.Hsapiens.dbSNP155.GRCh38
# mcps_bim_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles"
# external_gwas<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
# setwd("/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training")
# sink("chr_rsid.log")
# data_save<-c()
# data_dup_save<-c()
# for(i in 1:22){
#   cat("\n chromosome",i)
#   #currently working on genome build 38
#   data_path<-paste(mcps_bim_directory,"/mcps-freeze150k_qcd_chr",i,".bim",sep="")
#   data_in<-fread(data_path)
#   colnames(data_in)<-c("chr","chr_pos","V3","pos","A1","A2")
#   data_in$identifier<-rownames(data_in)
#   my_snps1<-GPos(Rle(c(i), c(nrow(data_in))), pos=c(data_in$pos),
#                  identifier=data_in$identifier,A1=data_in$A1,A2=data_in$A2)
#   cat ("\n perform snp overlap...")
#   known_snps1 <- snpsByOverlaps(snps, my_snps1)#find rsid in the reference list
#   length(known_snps1)#
#   hits1<- findOverlaps(my_snps1, known_snps1)#find duplicates in the list
# 
#   mapping <- selectHits(hits1, select="first")#only maps the first one
#   mcols(my_snps1)$RefSNP_id <- mcols(known_snps1)$RefSNP_id[mapping]
#   data_in$rsid<-data.frame(my_snps1)[,7]
#   data_in_up<-data_in[is.na(data_in$rsid)==F,]
#   data_in_up_na<-data_in[is.na(data_in$rsid)==T,]
#   data_in_up_na$rsid<-data_in_up_na$chr_pos
#   data_in_up<-rbind(data_in_up,data_in_up_na)
#   data_up<-data_in_up[order(data_in_up$chr,data_in_up$pos,decreasing = F),]
# 
#   if(sum(duplicated(queryHits(hits1)))!=0){
#     cat("\nsome SNPs map to more than one rsid")
# 
#     query_hits<-queryHits(hits1)#get ids
#     duplicatedhits<-unique(queryHits(hits1)[duplicated(queryHits(hits1))])#number of unique duplicated hits
#     cat("\n number of SNPs with duplicated rsid:",length(duplicatedhits))
#     subject_hits<-hits1[hits1@from%in%duplicatedhits]@to#get mapping rsid id
#     dup_hits<-hits1[hits1@from%in%duplicatedhits]
#     mcols(dup_hits)$rsid<-mcols(known_snps1)$RefSNP_id[c(subject_hits)]
#     #get all dups order
#     duplicatedhits_order<-queryHits(hits1)[queryHits(hits1)%in%duplicatedhits]
#     mcols(dup_hits)$chr_pos<-data_up$chr_pos[duplicatedhits_order]
# 
#     dup_index<-data.frame(dup_hits)[c(1,3,4)]
#     colnames(dup_index)[1]<-"identifier"
#     dup_index$identifier<-as.character(dup_index$identifier)
#     dup_index_up<-left_join(dup_index,data_up[,1:7],by=c("identifier","chr_pos"))
#     dup_index_up<-dup_index_up[,2:8]
#     data_dup_save<-rbind(data_dup_save,dup_index_up)
#   }
#   data_up<-data_up[,c(1:6,8)]
#   data_save<-rbind(data_save,data_up)
# 
#   gc()
# 
# 
# }
# 
# 
# data_save<-data_save[,c(1,2,4:7)]
# detach("package:SNPlocs.Hsapiens.dbSNP155.GRCh38")
# 
# #external GWAS----------------------------------------
# library(SNPlocs.Hsapiens.dbSNP155.GRCh37)
# snps <- SNPlocs.Hsapiens.dbSNP155.GRCh37
# working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
# setwd(working_directory)
# data_UKB<-fread("CAD_UKBIOBANK_ucsc_meta-analysis_input.txt")
# data_UKB<-data_UKB%>%select(uniqid,chr,pos,effect_allele,non_effect_allele,oldID,position,marker_no_allele)#position=hg38
# 
# data_save_up<-data_UKB[!data_UKB$oldID%in%data_save$rsid,]#rsid not in list
# #data_save_present<-data_UKB[data_UKB$oldID%in%data_save$rsid,]
# 
# data_save_up<-data_save_up%>%select(chr,marker_no_allele,position,effect_allele,non_effect_allele,oldID)
# colnames(data_save_up)<-colnames(data_save)
# sum(is.na(data_save_up$chr_pos))
# 
# 
# data_save_addukb<-rbind(data_save,data_save_up)
# #----------------------------
# data_cc4d<-fread("cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt")
# 
# data_cc4d<-data_cc4d%>%select(chr,pos,effect_allele,non_effect_allele,markername,position,marker_no_allele)#position=hg38
# 
# data_save_up<-data_cc4d[!data_cc4d$markername%in%data_save_addukb$rsid,]#rsid not in list
# #data_save_present<-data_cc4d[data_cc4d$markername%in%data_save_addukb$rsid,]
# 
# data_save_up<-data_save_up%>%select(chr,marker_no_allele,position,effect_allele,non_effect_allele,markername)
# colnames(data_save_up)<-colnames(data_save)
# sum(is.na(data_save_up$chr_pos))
# 
# 
# data_save_addukb_cc4d<-rbind(data_save_addukb,data_save_up)
# 
# #----------------------------------------------------------------------
# library(SNPlocs.Hsapiens.dbSNP155.GRCh37)
# snps <- SNPlocs.Hsapiens.dbSNP155.GRCh37
# working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
# setwd(working_directory)
# data_BBJ<-fread("BBJCAD_2020_ucsc_meta-analysis_input.txt")
# 
# data_BBJ<-data_BBJ%>%select(chr,pos,effect_allele,non_effect_allele,marker_no_allele,position)
# data_BBJ$identifier<-rownames(data_BBJ)
# 
# my_snps1<-GPos(Rle(c(data_BBJ$chr), c(rep(1,nrow(data_BBJ)))), pos=c(data_BBJ$pos),identifier=data_BBJ$identifier)
# cat ("\n perform snp overlap...")
# known_snps1 <- snpsByOverlaps(snps, my_snps1)
# 
# hits1<- findOverlaps(my_snps1, known_snps1)
# mapping <- selectHits(hits1, select="first")
# mcols(my_snps1)$RefSNP_id <- mcols(known_snps1)$RefSNP_id[mapping]
# 
# data_BBJ$rsid<-data.frame(my_snps1)[,"RefSNP_id"]
# data_BBJ_up<-data_BBJ[is.na(data_BBJ$rsid)==F,]
# data_BBJ_up_na<-data_BBJ[is.na(data_BBJ$rsid)==T,]
# data_BBJ_up_na$rsid<-data_BBJ_up_na$marker_no_allele
# data_BBJ_up<-rbind(data_BBJ_up,data_BBJ_up_na)
# data_up<-data_BBJ_up[order(data_BBJ_up$chr,data_BBJ_up$pos,decreasing = F),]
# 
# data_save_up<-data_up[!data_up$rsid%in%data_save_addukb_cc4d$rsid,]
# data_save_up<-data_save_up%>%select(chr,marker_no_allele,position,effect_allele,non_effect_allele,rsid)
# colnames(data_save_up)<-colnames(data_save_addukb_cc4d)
# sum(is.na(data_save_up$chr_pos))
# 
# 
# data_save_addukb_cc4d_bbj<-rbind(data_save_addukb_cc4d,data_save_up)
# data_save_addukb_cc4d_bbj<-data_save_addukb_cc4d_bbj[order(data_save_addukb_cc4d_bbj$chr,data_save_addukb_cc4d_bbj$pos,decreasing = F),]
# saveRDS(data_save_addukb_cc4d_bbj,"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_rsid_list.rds")
# gc()
# if(sum(duplicated(queryHits(hits1)))!=0){
#   cat("\nsome SNPs map to more than one rsid")
#   
#   query_hits<-queryHits(hits1)#get ids
#   duplicatedhits<-unique(queryHits(hits1)[duplicated(queryHits(hits1))])#number of unique duplicated hits
#   cat("\n number of SNPs with duplicated rsid:",length(duplicatedhits))
#   subject_hits<-hits1[hits1@from%in%duplicatedhits]@to#get mapping rsid id
#   dup_hits<-hits1[hits1@from%in%duplicatedhits]
#   mcols(dup_hits)$rsid<-mcols(known_snps1)$RefSNP_id[c(subject_hits)]
#   #get all dups order
#   duplicatedhits_order<-queryHits(hits1)[queryHits(hits1)%in%duplicatedhits]
#   mcols(dup_hits)$chr_pos<-data_up$marker_no_allele[duplicatedhits_order]
#   
#   dup_index<-data.frame(dup_hits)[,c(1,3,4)]
#   colnames(dup_index)[1]<-"identifier"
#   dup_index$identifier<-as.character( dup_index$identifier)
#   colnames(data_BBJ_up)[5]<-"chr_pos"
#   dup_index_up<-left_join(dup_index,data_BBJ_up[,c(1,3:7)],by=c("identifier","chr_pos"))
#   dup_index_up<-dup_index_up[,2:7]
#   data_dup_save<-data_dup_save[,c(1:3,5:7)]
#   dup_index_up<-dup_index_up%>%select(rsid,chr_pos,chr,position,effect_allele,non_effect_allele)
#   colnames(dup_index_up)<-colnames(data_dup_save)
#   data_dup_save_bbj<-rbind(data_dup_save,dup_index_up)
# } 
# 
# 
# data_dup_save_bbj<-data_dup_save_bbj[order(data_dup_save_bbj$chr,data_dup_save_bbj$pos,decreasing = F),]
# 
# saveRDS(data_dup_save_bbj,"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_dup_rsid_list.rds")
# 
# detach("package:SNPlocs.Hsapiens.dbSNP155.GRCh37")
# 
# sink()

rsid_list <- readRDS("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_rsid_list.rds")
dup_rsid_list <- readRDS("/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_dup_rsid_list.rds")
dup_rsid_list$check<-paste(dup_rsid_list$rsid,":",dup_rsid_list$A1,":",dup_rsid_list$A2,sep="")
check<-dup_rsid_list[!duplicated(dup_rsid_list$check),]

saveRDS(check,"/gpfs3/well/emberson/users/hma817/projects/MCPS_PRS_training/data/chrpos_dup_rsid_list.rds")
