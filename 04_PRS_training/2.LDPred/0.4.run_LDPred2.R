###LDPred computation script
## This script adapts from LDPred2 tutorial
rm(list=ls())

arg = commandArgs(trailingOnly=TRUE)
#set up libraries--------------------------------
library(data.table)
library(dplyr)
library(bigsnpr)
library(bigparallelr)
library(parallel)
#set up working paths-----------------------------
options(bigstatsr.check.parallel.blas = FALSE)
NCORES <- nb_cores()
cat(NCORES,"cores")
assert_cores(NCORES)
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred"
gwas_directory<-arg[1]
genotype_directory<-arg[2]
output_path<-arg[3]
onekg_genetics<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/1000-genomes-genetic-maps-master/interpolated_OMNI"
hapmap3_dir<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/map_hm3_plus_ldpred2.rds"
setwd(working_directory)
dir.create(output_path)
dir.create(paste0(output_path,"/",arg[5]))

sink(arg[4])#setup log file


#readin GWAS summary stats------------------------------------------------
cat("\n Start", format(Sys.time(), "%a %Y-%b-%d, %X "))
cat("\n Reading in summary stats from ....", paste(gwas_directory,"/",arg[5],"1.txt",sep=""))
sumstats <- fread(paste(gwas_directory,"/",arg[5],"1.txt",sep=""))
colnames(sumstats)[c(1:5,10:12)]<-c("chr","pos","marker","a1", "a0","beta","beta_se","p")
sumstats$a1<-toupper(sumstats$a1)
sumstats$a0<-toupper(sumstats$a0)
cat("\nGWAS feature \n")
print(str(sumstats))

#calculating effective sample size for binary traits 
sumstats$n_eff <- 4 / (1 / sumstats$case + 1 / sumstats$control)#binary traits
sumstats$n_eff1<-quantile(8 / sumstats$beta_se^2, 0.999)#recommeded for meta-analysis GWAS



#input hapmap3+ variants, recommended by LDPred 2 tutorial
info<-readRDS(hapmap3_dir)
info$marker<-paste0("chr",info$chr,":",info$pos_hg38)
cat("\nHAPMAP3+ contains", nrow(info)," SNPs")
cat("\n Retain SNPs in HAPMAP3+...")
sumstats_up <- sumstats[sumstats$marker%in% info$marker,]
cat("\n Summary stats input now contains", nrow(sumstats_up), "SNPs")


#LD matrix calculation------------------------------------------------------
cat("\n Calculating LD Matrix...")
tmp <- tempfile(tmpdir = paste(output_path,"/tmp-data",sep=""))
tmp_name<-tmp
cat("\n Creating temporary file at ", tmp, "this file will be removed once LD matrix computation finished.")

# Initialize variables for storing the LD score and LD matrix
corr <- NULL
ld <- NULL
maf_all<-NULL
# We want to know the ordering of samples in the bed file 
info_snp <- NULL
fam.order <- NULL

for (chr_id in 1:22) {
  cat("\n\n LD matrix computation for chromosome", chr_id)
  # now attach the genotype object
  obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
  # extract the SNP information from the genotype
  map <- obj.bigSNP$map[-3]
  names(map) <- c("chr", "marker", "pos", "a1", "a0")
  # perform SNP matching
  # tmp_snp <- snp_match(sumstats[sumstats$chr==chr_id,], map)
  cat("\n Matching SNPs in genotyping file...")
  tmp_snp1 <- snp_match(sumstats_up[sumstats_up$chr==chr_id,],map)
  cat("\n",nrow(tmp_snp1)," matched SNPs.")
  # Assign the genotype to a variable for easier downstream analysis
  genotype <- obj.bigSNP$genotypes
  # Rename the data structures
  CHR <- map$chr
  POS <- map$pos
  # get the CM information from 1000 Genome
  #information predownloaded
  cat("\n reading in 1kg CM information...")
  POS2 <- snp_asGeneticPos(CHR, POS, dir = onekg_genetics)
  ind.row <- rows_along(genotype)
  maf <- snp_MAF(genotype, ind.row = ind.row, ind.col = tmp_snp1$`_NUM_ID_`, ncores = NCORES)
  #maf_thr <- 1 / sqrt(length(ind.row))
  #maf <- as.numeric(arg[6])#input MAF threshold
  
  cat("\n MAF threshold set as ", as.numeric(arg[6]))

  # df_beta <- tmp_snp [tmp_snp$Freq1> maf, ]
  df_beta1 <- tmp_snp1 [maf> as.numeric(arg[6]), ]
  cat("\n", nrow(df_beta1)," SNPs retained based on MAF threshold.")
  info_snp <- rbind(info_snp, df_beta1 )#bind all retained snps into one data frame
  # calculate LD
  # Extract SNPs that are included in the chromosome
  ind.chr <- which(df_beta1$chr == chr_id)
  ind.chr2 <- df_beta1$`_NUM_ID_`[ind.chr]
  # Calculate the LD
  corr0 <- snp_cor(
    genotype,
    ind.col = ind.chr2,
    ncores = NCORES,
    infos.pos = POS2[ind.chr2],
    size = 3/1000
  )
  if (chr_id == 1) {
    ld <- Matrix::colSums(corr0^2)
    corr <- as_SFBM(corr0, tmp, compact = TRUE)
    maf_all<-c(maf)
  } else {
    ld <- c(ld, Matrix::colSums(corr0^2))
    corr$add_columns(corr0, nrow(corr))
    maf_all<-c(maf_all,maf)
  }
  # We assume the fam order is the same across different chromosomes
  if(is.null(fam.order)){
    fam.order <- as.data.table(obj.bigSNP$fam)
  }
}


df_beta1 <- info_snp[,c("beta", "beta_se", "n_eff","n_eff1", "_NUM_ID_")]
cat("\n\n Total SNPs retained:", nrow(df_beta1) )

cat("\n saving...",paste0(output_path,"/",arg[5],"/retainedSNPs",".rds"))
saveRDS(info_snp,paste0(output_path,"/",arg[5],"/retainedSNPs",".rds"))

cat("\n saving...",paste0(output_path,"/",arg[5],"/ldcorr",".rds"))
saveRDS(corr,paste0(output_path,"/",arg[5],"/ldcorr",".rds"))


cat("\n saving...",paste0(output_path,"/",arg[5],"/ld",".rds"))
saveRDS(ld,paste0(output_path,"/",arg[5],"/ld",".rds"))

cat("\n saving...",paste0(output_path,"/",arg[5],"/maf",".rds"))
saveRDS(maf_all,paste0(output_path,"/",arg[5],"/maf",".rds"))



#calculate h2 for LDPred input
for ( i in c("norm","meta-analysis")){
  cat("\n Computing LDPred results using effective sample size ", i," ......")
  if(i=="norm"){
    sample_size_in<-df_beta1$n_eff
  }else if(i=="meta-analysis"){
    sample_size_in<-df_beta1$n_eff1
  }
  ldsc <- snp_ldsc(   ld,
                      length(ld),
                      chi2 = (df_beta1$beta / df_beta1$beta_se)^2,
                      sample_size = sample_size_in,
                      blocks = NULL)
  h2_est <- ldsc[["h2"]]

  cat("\n\n heritability estimated:",h2_est)


#inf-----------------------------------------------------
cat("\n\n Computation if LDPred-Inf....")
beta_inf <- snp_ldpred2_inf(corr, df_beta1, h2 = h2_est)#one beta weight for each info SNP, in the same order as info snp

pred_inf <- NULL #will give one PRS for each included individuals
for(chr_id in 1:22){
  obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
  genotype <- obj.bigSNP$genotypes
  # calculate PRS for all samples
  ind.test <- 1:nrow(genotype)
  # Extract SNPs in this chromosome
  chr.idx <- which(info_snp$chr == chr_id)#search for retained snps in this specific chr
  ind.chr <- info_snp$`_NUM_ID_`[chr.idx]#get their ID on summary stats
  tmp <- big_prodVec(genotype,
                     beta_inf[chr.idx],#y.col =ind.col(i.e. ind.chr), so this is beta weight for snps in this chromosome
                     ind.row = ind.test,
                     ind.col = ind.chr)
  if(is.null(pred_inf)){
    pred_inf <- tmp
  }else{
    pred_inf <- pred_inf + tmp
  }
}
cat("\n saving...",paste0(output_path,"/",arg[5],"/ldpred-inf-beta_",i,".rds"))
saveRDS(beta_inf,paste0(output_path,"/",arg[5],"/ldpred-inf-beta_",i,".rds"))
cat("\n saving...",paste0(output_path,"/",arg[5],"/ldpred-inf-pred_",i,".rds"))
saveRDS(pred_inf,paste0(output_path,"/",arg[5],"/ldpred-inf-pred_",i,".rds"))
##grid--------------------------------
# Prepare data for grid model
cat("\n\n Computation if LDPred-grid....")
input_p<-as.numeric(strsplit(arg[7],split=",")[[1]])
p_seq <- signif(seq_log(input_p[1], 1, length.out = input_p[2]), 2)
cat("\n input p-values: ",p_seq)
input_h2<-as.numeric(strsplit(arg[8],split=",")[[1]])
h2_seq <- round(h2_est * c(input_h2), 4)
cat("\n input h2s: ",input_h2)

grid.param <-
  expand.grid(p = p_seq,
              h2 = h2_seq,
              sparse = c(FALSE, TRUE))#the included parameter set will be length p_seq*length h2_seq*2

# Get adjusted beta from grid model
beta_grid <-
  snp_ldpred2_grid(corr, df_beta1, grid.param, ncores = NCORES)
#a matrix with ncol = all parameter sets and nrow= included snps

pred_grid <- NULL#one PRS for each parameter set for each individual
for(chr_id in 1:22){
  obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
  genotype <- obj.bigSNP$genotypes
  # calculate PRS for all samples
  ind.test <- 1:nrow(genotype)
  # Extract SNPs in this chromosome
  chr.idx <- which(info_snp$chr == chr_id)
  ind.chr <- info_snp$`_NUM_ID_`[chr.idx]

  tmp <- big_prodMat( genotype,
                      beta_grid[chr.idx,],
                      ind.col = ind.chr)#y.col =ind.col(i.e. ind.chr)

  if(is.null(pred_grid)){
    pred_grid <- tmp
  }else{
    pred_grid <- pred_grid + tmp
  }
}

grid.param$name<-paste(grid.param$p,grid.param$h2,grid.param$sparse,sep="_")
colnames(pred_grid)<-grid.param$name
colnames(beta_grid)<-grid.param$name
rownames(beta_grid)<-info_snp$marker.ss
cat("\n saving...",paste0(output_path,"/",arg[5],"/ldpred-grid-beta_",i,".rds"))
saveRDS(beta_grid,paste0(output_path,"/",arg[5],"/ldpred-grid-beta_",i,".rds"))
cat("\n saving...",paste0(output_path,"/",arg[5],"/ldpred-grid-pred_",i,".rds"))
saveRDS(pred_grid,paste0(output_path,"/",arg[5],"/ldpred-grid-pred_",i,".rds"))

#auto------------------------------------------------------------------------
# Get adjusted beta from the auto model
# cat("\n\n Computation if LDPred-auto....","used 100 different p-values ")
# multi_auto <- snp_ldpred2_auto(
#   corr,
#   df_beta1,
#   h2_init = h2_est,
#   vec_p_init = seq_log(1e-10, 0.9, length.out = 100),
#   ncores = NCORES
# )
# beta_auto <- rowMeans(sapply(multi_auto, function(auto)
#   auto$beta_est))
# 
# 
# pred_auto <- NULL
# for(chr_id in 1:22){
#   obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
#   genotype <- obj.bigSNP$genotypes
#   # calculate PRS for all samples
#   ind.test <- 1:nrow(genotype)
#   # Extract SNPs in this chromosome
#   chr.idx <- which(info_snp$chr == chr_id)
#   ind.chr <- info_snp$`_NUM_ID_`[chr.idx]
#   tmp <-
#     big_prodVec(genotype,
#                 beta_auto[chr.idx],
#                 ind.row = ind.test,
#                 ind.col = ind.chr)
#   if(is.null(pred_auto)){
#     pred_auto <- tmp
#   }else{
#     pred_auto <- pred_auto + tmp
#   }
# }
#
#cat("\n saving...",paste0(output_path,"/",arg[5],"ldpred-multi-auto.rds"))
# saveRDS(multi_auto,paste0(output_path,"/",arg[5],"ldpred-multi-auto.rds"))
#cat("\n saving...",paste0(output_path,"/",arg[5],"ldpred-auto-beta.rds"))
# saveRDS(beta_auto,paste0(output_path,"/",arg[5],"ldpred-auto-beta.rds"))
#cat("\n saving...",paste0(output_path,"/",arg[5],"ldpred-auto-pred.rds"))
# saveRDS(pred_auto,paste0(output_path,"/",arg[5],"ldpred-auto-pred.rds"))


cat("\n saving...",paste0(output_path,"/",arg[5],"/ldsc_",i,".rds"))
saveRDS(ldsc,paste0(output_path,"/",arg[5],"/ldsc_",i,".rds"))


cat("\n saving...",paste0(output_path,"/",arg[5],"/ldcorr_",i,".rds"))
saveRDS(corr,paste0(output_path,"/",arg[5],"/ldcorr_",i,".rds"))


cat("\n saving...",paste0(output_path,"/",arg[5],"/ld_",i,".rds"))
saveRDS(ld,paste0(output_path,"/",arg[5],"/ld_",i,".rds"))


cat("\n saving...",paste0(output_path,"/",arg[5],"/summstats_up_",i,".rds"))
saveRDS(sumstats_up,paste0(output_path,"/",arg[5],"/summstats_up_",i,".rds"))
saveRDS(fam.order,paste0(output_path,"/",arg[5],"/participants_order_",i,".rds"))}
#save participants order just to double check participants are in the correct order


#unlink(paste(tmp, ".sbk",sep=""), recursive = FALSE, force = T)
#total snps input for LD matrix 
cat("\n removing temporary file....")
file.remove(paste(tmp_name, ".sbk",sep=""))
cat("\n done", format(Sys.time(), "%a %Y-%b-%d, %X "))
sink()#close log file
