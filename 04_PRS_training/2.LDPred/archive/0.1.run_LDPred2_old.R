rm(list=ls())
#arg = commandArgs(trailingOnly=TRUE)
#set up libraries--------------------------------
library(data.table)
library(dplyr)
library(bigsnpr)
library(bigparallelr)
library(parallel)
#set up working paths-----------------------------
options(bigstatsr.check.parallel.blas = FALSE)
(NCORES <- nb_cores())
print(NCORES)
assert_cores(NCORES)
working_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/2.LDPred"
gwas_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/gwas_regenie/CAD_EPA_80_fold_1/meta-analysis"
genotype_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/data/bfiles/fold1"
validation_data_ID<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/crossfold/CAD_EPA/1/validation_data.txt"
output_path<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/2.LDPred/fold1"
onekg_genetics<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/1000-genomes-genetic-maps-master/interpolated_OMNI"
hapmap3_dir<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/map_hm3_ldpred2.rds"
setwd(working_directory)

#sink(paste(working_directory,"/out/fold1/LDPred_out.txt",sep=""))#setup log file


#readin GWAS summary stats------------------------------------------------
cat("reading in summary stats from ....", paste(gwas_directory,"/metal_ukb_cc4d1.txt",sep=""))
sumstats <- fread(paste(gwas_directory,"/metal_ukb_cc4d1.txt",sep=""))#needs automation
colnames(sumstats)[c(1:5,10:12)]<-c("chr","pos","marker","a1", "a0","beta","beta_se","p")
sumstats$a1<-toupper(sumstats$a1)
sumstats$a0<-toupper(sumstats$a0)
cat("\nGWAS feature \n")
print(str(sumstats))

sumstats$n_eff <- 4 / (1 / sumstats$case + 1 / sumstats$control)#binary traits
sumstats$n_eff1<-quantile(8 / sumstats$beta_se^2, 0.999)
info<-readRDS("/well/emberson/users/hma817/projects/MCPS_PRS_training/external_data/map_hm3_plus_ldpred2.rds")
info$marker<-paste0("chr",info$chr,":",info$pos_hg38)
sumstats_up <- sumstats[sumstats$marker%in% info$marker,]




  

#LD matrix calculation
tmp <- tempfile(tmpdir = paste(output_path,"/tmp-data",sep=""))
print(tmp)
# Initialize variables for storing the LD score and LD matrix
corr <- NULL
ld <- NULL
# We want to know the ordering of samples in the bed file 
info_snp <- NULL
fam.order <- NULL

 for (chr_id in 1:22) {

  # now attach the genotype object
  obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
  # extract the SNP information from the genotype
  map <- obj.bigSNP$map[-3]
  names(map) <- c("chr", "marker", "pos", "a1", "a0")
  # perform SNP matching
 # tmp_snp <- snp_match(sumstats[sumstats$chr==chr_id,], map)
  tmp_snp1 <- snp_match(sumstats_up[sumstats_up$chr==chr_id,],map)
  
  
  # Assign the genotype to a variable for easier downstream analysis
  genotype <- obj.bigSNP$genotypes
  # Rename the data structures
  CHR <- map$chr
  POS <- map$pos
  # get the CM information from 1000 Genome
  # will download the 1000G file to the current directory (".")
  POS2 <- snp_asGeneticPos(CHR, POS, dir = onekg_genetics)
  ind.row <- rows_along(genotype)
  maf <- 0.05
  # threshold I like to use
 # df_beta <- tmp_snp [tmp_snp$Freq1> maf, ]
  df_beta1 <- tmp_snp1 [tmp_snp1$Freq1> maf, ]
  info_snp <- rbind(info_snp, df_beta1 )
  # calculate LD
  # Extract SNPs that are included in the chromosome
  ind.chr <- which(df_beta1$chr == chr_id)
  ind.chr2 <- tmp_snp1$`_NUM_ID_`[ind.chr]
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
  } else {
    ld <- c(ld, Matrix::colSums(corr0^2))
    corr$add_columns(corr0, nrow(corr))
  }
  # We assume the fam order is the same across different chromosomes
  if(is.null(fam.order)){
    fam.order <- as.data.table(obj.bigSNP$fam)
  }
  }




df_beta1 <- info_snp[,c("beta", "beta_se", "n_eff", "_NUM_ID_")]
ldsc <- snp_ldsc(   ld, 
                    length(ld), 
                    chi2 = (df_beta1$beta / df_beta1$beta_se)^2,
                    sample_size = df_beta1$n_eff, 
                    blocks = NULL)
h2_est <- ldsc[["h2"]]



#inf-----------------------------------------------------
beta_inf <- snp_ldpred2_inf(corr, df_beta1, h2 = h2_est)#one beta weight for each info SNP, in the same order

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

saveRDS(beta_inf,paste0(output_path,"/metal_ukb_cc4d_ldpred-inf-beta.rds"))
saveRDS(pred_inf,paste0(output_path,"/metal_ukb_cc4d_ldpred-inf-pred.rds"))
##grid--------------------------------
# Prepare data for grid model
p_seq <- signif(seq_log(1e-4, 1, length.out = 17), 2)
h2_seq <- round(h2_est * c(0.7, 1, 1.4), 4)
grid.param <-
  expand.grid(p = p_seq,
              h2 = h2_seq,
              sparse = c(FALSE, TRUE))#the included parameter set will be length p_seq*length h2_seq*2

# Get adjusted beta from grid model
beta_grid <-
  snp_ldpred2_grid(corr, df_beta1, grid.param, ncores = NCORES)#a matrix with ncol = all parameter sets and nrow= included snps



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
                      ind.col = ind.chr)
  
  if(is.null(pred_grid)){
    pred_grid <- tmp
  }else{
    pred_grid <- pred_grid + tmp
  }
}



saveRDS(beta_grid,paste0(output_path,"/metal_ukb_cc4d_ldpred-grid-beta.rds"))
saveRDS(pred_grid,paste0(output_path,"/metal_ukb_cc4d_ldpred-grid-pred.rds"))

#auto------------------------------------------------------------------------
# Get adjusted beta from the auto model
multi_auto <- snp_ldpred2_auto(
  corr,
  df_beta1,
  h2_init = h2_est,
  vec_p_init = seq_log(1e-10, 0.9, length.out = 100),
  ncores = NCORES
)
beta_auto <- rowMeans(sapply(multi_auto, function(auto)
  auto$beta_est))


pred_auto <- NULL
for(chr_id in 1:22){
  obj.bigSNP <- snp_attach(paste0(genotype_directory,"/mcps-subset-chr",chr_id,".rds"))
  genotype <- obj.bigSNP$genotypes
  # calculate PRS for all samples
  ind.test <- 1:nrow(genotype)
  # Extract SNPs in this chromosome
  chr.idx <- which(info_snp$chr == chr_id)
  ind.chr <- info_snp$`_NUM_ID_`[chr.idx]
  tmp <-
    big_prodVec(genotype,
                beta_auto[chr.idx],
                ind.row = ind.test,
                ind.col = ind.chr)
  if(is.null(pred_auto)){
    pred_auto <- tmp
  }else{
    pred_auto <- pred_auto + tmp
  }
}
saveRDS(multi_auto,paste0(output_path,"/metal_ukb_cc4d_ldpred-multi-auto.rds"))
saveRDS(beta_auto,paste0(output_path,"/metal_ukb_cc4d_ldpred-auto-beta.rds"))
saveRDS(pred_auto,paste0(output_path,"/metal_ukb_cc4d_ldpred-auto-pred.rds"))

saveRDS(info_snp,paste0(output_path,"/metal_ukb_cc4d_retainedSNPs.rds"))
saveRDS(ldsc,paste0(output_path,"/metal_ukb_cc4d_ldsc.rds"))
saveRDS(corr,paste0(output_path,"/metal_ukb_cc4d_ldcorr.rds"))
saveRDS(ld,paste0(output_path,"/metal_ukb_cc4d_ld.rds"))
file.remove(paste0(tmp, ".sbk"))
#sink()#close log file
