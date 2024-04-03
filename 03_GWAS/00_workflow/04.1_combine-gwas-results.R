# Author: Jason Matthew Torres
# Additions by: Mike Patrick Turner
# Description:
# This script consolidates GWAS results across chromosomes into a single data
# frame and writes output into a single compressed file. The script also
# calculates lambda inflation factor and generates and saves a QQ-plot.

# Usage:
# module load R/3.6.2-foss-2019b
# Rscript 04.1_combine-gwas-results.R method output_directory
#
# Note: method must be one of: "plink", "regenie", "sugen", or "mtag".
# Note: output_directory must be the directory where the GWAS result files are
# located (i.e. per-chromosomes compressed output files)
# Note: for MTAG, a new folder should be created for each trait output file
# and one results file move there. This is to be used as the output_directory
# argument.

"%&%" <- function(a,b) paste0(a,b)
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("data.table"))
suppressPackageStartupMessages(library("stringr"))
suppressPackageStartupMessages(library("qqman"))
args = commandArgs(trailingOnly=TRUE)
model <- args[1]
if (!(model %in% c("plink","regenie","sugen","mtag"))){stop("method must be one of:"%&%
"'plink','regenie', 'sugen', or 'mtag'")}
out.dir <- args[2]
out.dir <- ifelse(str_sub(out.dir,-1)=="/",out.dir,out.dir%&%"/")
plot.dir <- out.dir %&% "plots/"
if (!dir.exists(plot.dir)){ dir.create(plot.dir)}
## Combine GWAS results and write output
if (model == "mtag"){print("No need to combine MTAG results...")
  gwas.df <- fread(out.dir %&% "combined-gwas-results.txt.gz") 
  names(gwas.df) <- c("ID", "CHR", "BP", "A1", "A2", "Z", "N", "FRQ", "mtag_beta", "mtag_se", "mtag_z", "P")
  } else {print("Combining GWAS result files...")
    file.vec <- list.files(out.dir)
    file.vec <- file.vec[grepl("\\.gz",file.vec)&grepl("chr",file.vec)]
    chrom.vec <- c("chr" %&% 1:22, "chrX")
    gwas.df <- c()
    for (chrom in chrom.vec){
      print("\nChromosome: " %&% strsplit(chrom,split="chr")[[1]][2])
      if (model=="plink"){
        chrom.file = file.vec[grepl("-"%&%chrom%&%"\\.",file.vec)]
        if (length(chrom.file)!=0){
            if (!file.exists(out.dir%&%chrom.file)){
              warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
            } else{
              sub.df <- fread(cmd="cat " %&% out.dir %&% chrom.file %&% " | zmore")
              gwas.df <- rbind(gwas.df,sub.df)
            }
        } else{
          warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
        }
      } else if (model=="regenie"){
        chrom.file = file.vec[grepl("-"%&%chrom%&%"_",file.vec)]
        if (length(chrom.file)!=0){
            if (!file.exists(out.dir%&%chrom.file)){
              warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
            } else{
              sub.df <- fread(cmd="cat " %&% out.dir %&% chrom.file %&% " | zmore")
              sub.df$P <- 10^(-sub.df$LOG10P)
              gwas.df <- rbind(gwas.df,sub.df)
            }
        } else{
          warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
        }
      } else if (model=="sugen"){
        chrom.files = file.vec[grepl("-"%&%chrom%&%"\\.",file.vec)]
        print("Reading in chunks for "%&%chrom%&%"...")
        pb<-txtProgressBar(min=0,max=length(chrom.files),style=3)
        for (i in 1:length(chrom.files)){
          setTxtProgressBar(pb,i)
          chrom.file <- chrom.files[i]
          if (length(chrom.file)!=0){
              if (!file.exists(out.dir%&%chrom.file)){
                warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
              } else{
                sub.df <- fread(cmd="cat " %&% out.dir %&% chrom.file %&% " | zmore")
                names(sub.df)[dim(sub.df)[2]] <- "P"
                index <- (1:length(names(sub.df)))[grepl("VCF_ID",names(sub.df))]
                names(sub.df)[index] <- "ID"
                gwas.df <- rbind(gwas.df,sub.df)
              }
          } else{
            warning("Result file for "%&%chrom%&%" does not exist. Please inspect.")
          }
        }
      } else{
        stop("No valid method given.")
      }
    }
  warnings()
  print("Writing output file: " %&% out.dir %&% "combined-gwas-results.txt.gz")
  gz1 <- gzfile(out.dir %&% "combined-gwas-results.txt.gz", "w")
  write.table(gwas.df, gz1,sep="\t",col.names=T,row.names=F,quote=F)
  close(gz1)
  }

## Create subsetted data frame to use for generating Manhattan plot
print("Creating subsetted data frame to be used for Manhattan plot...")
sig <- 5e-8
sig.df <- filter(gwas.df, P< 0.01)
to_sample <- 1e6 - nrow(sig.df)
null_count <- (to_sample/2) %>% round(.)
print(null_count)

notsig.df <- filter(gwas.df, !(ID %in% sig.df$ID))
notsig.dfa <- filter(gwas.df, P >= 0.001, P < 0.05)
notsig.dfb <- filter(notsig.df, P > 0.01)
rm(notsig.df)
print(nrow(notsig.dfa))
print(nrow(notsig.dfb))
keep_index1 <- sample(1:nrow(notsig.dfa), size=min(null_count,nrow(notsig.dfa)), replace = F)
keep_index2 <- sample(1:nrow(notsig.dfb), size=min(null_count,nrow(notsig.dfb)), replace = F)
null_df1 <- notsig.dfa[keep_index1, ]
null_df2 <- notsig.dfb[keep_index2, ]
rm(notsig.dfa)
rm(notsig.dfb)
plot.df <- rbind(null_df1, null_df2, sig.df)
print("Writing output file: " %&% out.dir %&% "manhattan-input.txt.gz")
gz2 <- gzfile(out.dir %&% "manhattan-input.txt.gz", "w")
write.table(plot.df, gz2,sep="\t",col.names=T,row.names=F,quote=F)
close(gz2)
## Report significant variant counts and inflation factor
print("There are " %&% dim(sig.df)[1] %&% " significant variants.\n")
name.vec <- names(gwas.df)
if ("BETA" %in% name.vec & "SE" %in% name.vec){
  gwas.df$Z <- gwas.df$BETA/gwas.df$SE
  inflation.factor <- median((na.omit(gwas.df$Z)^2)/qchisq(1/2,df=1))
} else if ("Z_STAT" %in% name.vec){
  inflation.factor <- median((na.omit(gwas.df$Z_STAT)^2)/qchisq(1/2,df=1))
} else if ("mtag_z" %in% name.vec){
  inflation.factor <- median((na.omit(gwas.df$mtag_z)^2)/qchisq(1/2,df=1))
}  else{
  inflation.factor <- NA
  warning("Columns 'BETA' and 'SE' or 'Z_STAT' or 'mtag_z' are not in gwas output." %&%
  " Could not calculate lambda. Please inspect.")
}
print("Observed lambda inflation factor: " %&% inflation.factor %&% "\n")
# Generate QQ-plot
print("Saving QQ-plot image file: " %&% plot.dir %&% "qq.png")
png(filename = plot.dir %&% "qq.png",type="cairo")
qq(gwas.df$P,main="Inflation Factor: " %&% round(inflation.factor,digits=3))
dev.off()

if (dim(sig.df)[1]>0){
  print("Printing Genome-wide significant associations")
  gz3 <- gzfile(out.dir %&% "genome-wide-significant.txt.gz", "w")
  write.table(filter(sig.df, P < sig), gz3,sep="\t",col.names=T,row.names=F,quote=F)
  close(gz3)
}
