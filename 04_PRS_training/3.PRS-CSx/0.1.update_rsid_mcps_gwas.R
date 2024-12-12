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
library(SNPlocs.Hsapiens.dbSNP155.GRCh38)
#library(SNPlocs.Hsapiens.dbSNP155.GRCh37)
snps <- SNPlocs.Hsapiens.dbSNP155.GRCh38

working_directory<-arg[1]
cat("set working directory as", working_directory)
setwd(working_directory)

cat("\n readin data...")
data_in<-fread(arg[2])#"data_mcps_meta-analysis_input.txt"

#data_in_up<-data_in[!data_in$marker_no_allele%in%data_in$marker_no_allele[duplicated(data_in$marker_no_allele)],]
# 
# for(i in 1:22){
#   cat("chromosome",i)
#   data_chr<-data_in[data_in$chr==i,]
if(is.na(arg[3])==F&arg[3]=="metal"){
  colnames(data_in)[c(1:6,10:12)]<-c("chr","position","marker_no_allele","effect_allele","non_effect_allele","effect_allele_freq",
                       "beta","se","pval")
  data_in$effect_allele<-toupper(data_in$effect_allele)
  data_in$non_effect_allele<-toupper(data_in$non_effect_allele)
}
  data_in$identifier<-rownames(data_in)
  cat(" \n set up GRange objects...")
  my_snps1<-GPos(Rle(c(data_in$chr), c(rep(1,nrow(data_in)))), pos=c(data_in$position),identifier=data_in$identifier)
  cat ("\n perform snp overlap...")
  known_snps1 <- snpsByOverlaps(snps, my_snps1)
  hits1<- findOverlaps(my_snps1, known_snps1)
  mapping <- selectHits(hits1, select="first")
  mcols(my_snps1)$RefSNP_id <- mcols(known_snps1)$RefSNP_id[mapping]
  
  if (anyDuplicated(queryHits(hits1))){
    warning("some SNPs are mapped to more than 1 known SNP")}
  mapping <- selectHits(hits1, select="all")
  data_in$rsid<-data.frame(my_snps1)[,5]
#}

gc()



data_in_up<-data_in[is.na(data_in$rsid)==F,]
data_in_up_na<-data_in[is.na(data_in$rsid)==T,]
data_in_up_na$rsid<-data_in_up_na$marker_no_allele
data_in_up<-rbind(data_in_up,data_in_up_na)
data_up<-data_in_up[order(data_in_up$chr,data_in_up$pos,decreasing = F),]


data_save<-data_up%>%select(rsid,effect_allele,non_effect_allele,beta,se)

colnames(data_save)<-c("SNP","A1","A2","BETA","SE")


cat("saving data......")

extracted_string <- sub("^metal_(.*)1\\.txt$", "\\1", arg[2])

if(arg[2]=="data_mcps_meta-analysis_input_nodup.txt"){
  write.table(data_up,"data_mcps_rsid.txt",quote = F,col.names = T,row.names = F,sep="\t")
  
  write.table(data_save,"data_mcps_prscsx.txt",quote = F,col.names = T,row.names = F,sep="\t")
  
}else{

write.table(data_save,paste0(extracted_string,"_prscsx.txt"),quote = F,col.names = T,row.names = F,sep="\t")
}








