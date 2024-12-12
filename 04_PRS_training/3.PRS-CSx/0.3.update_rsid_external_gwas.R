rm(list=ls())
arg = commandArgs(trailingOnly=TRUE)
# if (!require("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# 
# BiocManager::install("SNPlocs.Hsapiens.dbSNP155.GRCh38")
#set up libraries--------------------------------
#chromosom id position to rsid
library(data.table)
library(dplyr)
library(GenomicRanges)
if(arg[1]=="38"){
  library(SNPlocs.Hsapiens.dbSNP155.GRCh38)
  snps <- SNPlocs.Hsapiens.dbSNP155.GRCh38
}else if (arg[1]=="37"){
  library(SNPlocs.Hsapiens.dbSNP155.GRCh37)
  snps <- SNPlocs.Hsapiens.dbSNP155.GRCh37
}

#library(SNPlocs.Hsapiens.dbSNP155.GRCh37)


working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/GWAS_sources"
cat("set working directory as", working_directory)
setwd(working_directory)

cat("\n readin data...")
# data_in<-fread("CAD_UKBIOBANK_ucsc_meta-analysis_input.txt")
# 
# 
# data_up<-data_in%>%select(oldID,effect_allele,non_effect_allele,beta,se)
# colnames(data_up)<-c("SNP","A1","A2","BETA","SE")
# write.table(data_up,"CAD_UKBIOBANK_prscsx.txt",quote = F,col.names = T,row.names = F,sep="\t")
# 
# data_in<-fread("cc4d_1KG_additive_2015_ucsc_meta-analysis_input.txt")
# data_up<-data_in%>%select(markername,effect_allele,non_effect_allele,beta,se)
# colnames(data_up)<-c("SNP","A1","A2","BETA","SE")
# sum(is.na(data_up$SNP)==T)
# write.table(data_up,"cc4d_1KG_additive_2015_prscsx.txt",quote = F,col.names = T,row.names = F,sep="\t")
# 
# data_in<-fread("CC4D_UKB_meta_analysis_rsid1.txt")
# 
# data_up<-data_in%>%select(MarkerName,Allele1,Allele2,Effect,StdErr)
# data_up$Allele1<-toupper(data_up$Allele1)
# data_up$Allele2<-toupper(data_up$Allele2)
# colnames(data_up)<-c("SNP","A1","A2","BETA","SE")
#  write.table(data_up,"CC4D_UKB_rsid_prscsx.txt",quote = F,col.names = T,row.names = F,sep="\t")
# 
# 
# 



gwas_name<-arg[2]

data_in<-data.frame(fread(paste(gwas_name,".txt",sep="")))
data_in$identifier<-rownames(data_in)
cat(" \n set up GRange objects...")
chr=as.numeric(arg[3])
position=as.numeric(arg[4])
my_snps1<-GPos(Rle(c(data_in[,chr]), c(rep(1,nrow(data_in)))), pos=data_in[,position],identifier=data_in$identifier)
cat ("\n perform snp overlap...")
known_snps1 <- snpsByOverlaps(snps, my_snps1)
hits1<- findOverlaps(my_snps1, known_snps1)
mapping <- selectHits(hits1, select="first")
mcols(my_snps1)$RefSNP_id <- mcols(known_snps1)$RefSNP_id[mapping]

if (anyDuplicated(queryHits(hits1))){
  warning("some SNPs are mapped to more than 1 known SNP")
  print(sum(duplicated(queryHits(hits1))))
  }
mapping <- selectHits(hits1, select="first")
data_in$rsid<-data.frame(my_snps1)[,5]

data_in_up<-data_in[is.na(data_in$rsid)==F,]
data_in_up_na<-data_in[is.na(data_in$rsid)==T,]
if(arg[5]=="meta-input"){
  data_in_up_na$rsid<-data_in_up_na[,"marker_no_allele"]
}else if (arg[5]=="meta") {
  data_in_up_na$rsid<-data_in_up_na[,"MarkerName"]
}

data_in_up<-rbind(data_in_up,data_in_up_na)
data_up<-data_in_up[order(data_in_up$identifier,decreasing = F),]

if(arg[5]=="meta-input"){
data_save<-data_up%>%select(rsid,effect_allele,non_effect_allele,beta,se)
}else if (arg[5]=="meta"){
  data_save<-data_up%>%select(rsid,Allele1,Allele2,Effect,StdErr)
}


colnames(data_save)<-c("SNP","A1","A2","BETA","SE")
data_save$A1<-toupper(data_save$A1)
data_save$A2<-toupper(data_save$A2)
cat("\n saving data...")
write.table(data_save,paste(gwas_name,"_prscsx.txt",sep=""),quote = F,col.names = T,row.names = F,sep="\t")

