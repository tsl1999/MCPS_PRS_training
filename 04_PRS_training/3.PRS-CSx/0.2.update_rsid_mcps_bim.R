rm(list=ls())
arg = commandArgs(trailingOnly=TRUE)
# if (!require("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# 
# BiocManager::install("SNPlocs.Hsapiens.dbSNP155.GRCh38")
#set up libraries--------------------------------
#chromosom id position to rsid
library(data.table)
library(GenomicRanges)
library(SNPlocs.Hsapiens.dbSNP155.GRCh38)
#library(SNPlocs.Hsapiens.dbSNP155.GRCh37)
snps <- SNPlocs.Hsapiens.dbSNP155.GRCh38

#working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles"

working_directory<-arg[1]
setwd(working_directory)
chrom<-arg[2]
cat("chromosome", chrom)
cat("reading in data ...")
  data_in<-fread(paste("mcps-freeze150k_qcd_chr",chrom,".bim",sep=""))
  data_in<-data_in[!data_in$V2%in%data_in$V2[duplicated(data_in$V2)],]#remove duplicated snps
  cat(" \n set up GRange objects...")
  my_snps1<-GPos(Rle(c(chrom), c(nrow(data_in))), pos=c(data_in$V4))
  cat ("\n perform snp overlap...")
  known_snps1 <- snpsByOverlaps(snps, my_snps1)
  hits1<- findOverlaps(my_snps1, known_snps1)
  mapping <- selectHits(hits1, select="first")
  mcols(my_snps1)$RefSNP_id <- mcols(known_snps1)$RefSNP_id[mapping]
  data_in$rsid<-data.frame(my_snps1)[,4]
  # for(j in 1:nrow(data_in)){
  #   if(is.na(data_in$rsid[j])==T){
  #     cat("\n",j)
  #     data_in$rsid[j]<-data_in$V2[j]
  #   }
  # }


data_in_up<-data_in[is.na(data_in$rsid)==F,]
data_in_up_na<-data_in[is.na(data_in$rsid)==T,]
data_in_up_na$rsid<-data_in_up_na$V2
data_in_up<-rbind(data_in_up,data_in_up_na)
data_up<-data_in_up[order(data_in_up$V1,data_in_up$V4,decreasing = F),]
data_save<-data_up<-data_in_up[,c(1,7,3:6,2)]




#write.table(data_in,"mcps-freeze150k_qcd_chr.bim",quote = F,col.names = T,row.names = F,sep="\t")
cat ("\ saving data...")
write.table(data_save,paste("prscsx/mcps-freeze150k_rsid_chr",chrom,".bim",sep=""),quote = F,col.names = F,row.names = F,sep="\t")


