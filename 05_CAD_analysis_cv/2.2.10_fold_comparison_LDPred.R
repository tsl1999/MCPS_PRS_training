rm(list=ls())
library(data.table)
library(dplyr)
#model output readining in---------------------------------------------
results_directory<-"/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/2.LDPred"
setwd(results_directory)
sink("model_AUC_comparison.log")
model_gwas_compare_partial<-c()
model_gwas_compare_full<-c()
for(gwas in c("cc4d_bbj","ukb_cc4d","ukb_cc4d_bbj","ukb_ckb","ukb_ckb_cc4d_bbj",
              "his_ukb_cc4d", "his_all", "his_ukb_ckb_cc4d_bbj","his_ukb_cc4d_bbj")){
  model_compare_partial<-c()
  model_compare_full<-c()
  for(fold in 1:10){
    working_directory<-paste("/well/emberson/users/hma817/projects/MCPS_PRS_training/Training_data/PRS/2.LDPred/fold",fold,"/metal_",gwas,sep="")
    
    partial<-readRDS(paste(working_directory,"/logistic_model_output_partial.rds",sep=""))
    full<-readRDS(paste(working_directory,"/logistic_model_output_full.rds",sep=""))
    simple<-readRDS(paste(working_directory,"/logistic_model_output_simple.rds",sep=""))
      
    partial_auc<-partial%>%select(AUC)
    partial_auc$AUC<-as.numeric(partial_auc$AUC)
    partial_auc$parameter<-rownames(partial_auc)
    colnames(partial_auc)[1]<-paste("AUC",fold,sep="")
    partial_auc<-partial_auc[,c(2,1)]
    
    full_auc<-full%>%select(AUC)
    full_auc$AUC<-as.numeric(full_auc$AUC)
    colnames(full_auc)[1]<-paste("AUC",fold,sep="")
    full_auc$parameter<-rownames(full_auc)
    full_auc<-full_auc[,c(2,1)]
    
    
    simple_auc<-simple%>%select(AUC)
    simple_auc$AUC<-as.numeric(simple_auc$AUC)
    colnames(simple_auc)[1]<-paste("AUC",fold,sep="")
    simple_auc$parameter<-rownames(simple_auc)
    simple_auc<-simple_auc[,c(2,1)]
    
    
    if(fold==1){
      model_compare_partial<-partial_auc
      model_compare_full<-full_auc
      model_compare_simple<-simple_auc
    }else{
     
      new_row_partial<-data.frame(c(rownames(partial_auc)[!rownames(partial_auc)%in%model_compare_partial$parameter]))
      colnames(new_row_partial)[1]<-"parameter"
      rownames(new_row_partial)<-new_row_partial$parameter
      if(nrow(new_row_partial)!=0){
        new_row_partial[,2:ncol(model_compare_partial)]<-NA
        colnames(new_row_partial)[2:ncol(model_compare_partial)]<-colnames(model_compare_partial)[2:ncol(model_compare_partial)]
        model_compare_partial_new<-rbind(model_compare_partial,new_row_partial)
      }else{
        model_compare_partial_new<-model_compare_partial
      }
      model_compare_partial<-left_join(model_compare_partial_new,partial_auc,by="parameter")
      
      
      new_row_full<-data.frame(c(rownames(full_auc)[!rownames(full_auc)%in%model_compare_full$parameter]))
      colnames(new_row_full)[1]<-"parameter"
      rownames(new_row_full)<-new_row_full$parameter
      if(nrow(new_row_full)!=0){
        new_row_full[,2:ncol(model_compare_full)]<-NA
        colnames(new_row_full)[2:ncol(model_compare_full)]<-colnames(model_compare_full)[2:ncol(model_compare_full)]
        model_compare_full_new<-rbind(model_compare_full,new_row_full)
      }else{
        model_compare_full_new<-model_compare_full
      }
     
      model_compare_full<-left_join(model_compare_full_new,full_auc,by="parameter")
      
      
      new_row_simple<-data.frame(c(rownames(simple_auc)[!rownames(simple_auc)%in%model_compare_simple$parameter]))
      colnames(new_row_simple)[1]<-"parameter"
      rownames(new_row_simple)<-new_row_simple$parameter
      if(nrow(new_row_simple)!=0){
        new_row_simple[,2:ncol(model_compare_simple)]<-NA
        colnames(new_row_simple)[2:ncol(model_compare_simple)]<-colnames(model_compare_simple)[2:ncol(model_compare_simple)]
        model_compare_simple_new<-rbind(model_compare_simple,new_row_simple)
      }else{
        model_compare_simple_new<-model_compare_simple
      }
      
      model_compare_simple<-left_join(model_compare_simple_new,simple_auc,by="parameter")
    }
    
  }
  
  
  
  
  rownames(model_compare_partial)<-model_compare_partial$parameter
  rownames(model_compare_full)<-model_compare_full$parameter
  rownames(model_compare_simple)<-model_compare_simple$parameter
  
  model_compare_partial$na_sum<-rowSums(is.na(model_compare_partial[,2:11]))
  model_compare_partial$meanAUC<-rowMeans(model_compare_partial[,2:11],na.rm = T)
  model_compare_full$na_sum<-rowSums(is.na(model_compare_full[,2:11]))
  model_compare_full$meanAUC<-rowMeans(model_compare_full[,2:11],na.rm=T)
  model_compare_simple$na_sum<-rowSums(is.na(model_compare_simple[,2:11]))
  model_compare_simple$meanAUC<-rowMeans(model_compare_simple[,2:11],na.rm=T)
  
  
  model_compare_partial<-model_compare_partial[order(model_compare_partial$meanAUC,decreasing = T),]
  model_compare_full<-model_compare_full[order(model_compare_full$meanAUC,decreasing = T),]
  model_compare_simple<-model_compare_simple[order(model_compare_simple$meanAUC,decreasing = T),]
  
  #plot(model_compare_full$meanAUC,type="p",ylim=c(0.759,0.761))
  #plot(model_compare_partial$meanAUC,type="p",ylim=c(0.729,0.731))
  cat("\nparameter with the highest auc in partial model of gwas ",gwas,"is ",
      model_compare_partial[1,1],"with AUC: ",model_compare_partial[1,"meanAUC"],"with missing folds",model_compare_partial[1,"na_sum"] )
  cat("\nparameter with the highest auc in full model of gwas ",gwas,"is",
      model_compare_full[1,1],"with AUC: ",model_compare_full[1,"meanAUC"],"with missing folds",model_compare_full[1,"na_sum"] )
  
  saveRDS(model_compare_partial,paste(results_directory,"/model_compare_partial_",gwas,".rds",sep=""))
  saveRDS(model_compare_full,paste(results_directory,"/model_compare_full_",gwas,".rds",sep=""))
  saveRDS(model_compare_simple,paste(results_directory,"/model_compare_simple_",gwas,".rds",sep=""))
  
  final_compare_partial<-model_compare_partial%>%select(parameter,meanAUC,na_sum)
  colnames(final_compare_partial)[2:3]<-paste(colnames(final_compare_partial)[2:3],gwas,sep="_")
  
  final_compare_full<-model_compare_full%>%select(parameter,meanAUC,na_sum)
  colnames(final_compare_full)[2:3]<-paste(colnames(final_compare_full)[2:3],gwas,sep="_")
  
  final_compare_simple<-model_compare_simple%>%select(parameter,meanAUC,na_sum)
  colnames(final_compare_simple)[2:3]<-paste(colnames(final_compare_simple)[2:3],gwas,sep="_")
  
  
  if(which(gwas==c("cc4d_bbj","ukb_cc4d","ukb_cc4d_bbj","ukb_ckb","ukb_ckb_cc4d_bbj",
                   "his_ukb_cc4d", "his_all", "his_ukb_ckb_cc4d_bbj","his_ukb_cc4d_bbj"))==1){
    model_gwas_compare_partial<-final_compare_partial
    model_gwas_compare_full<-final_compare_full
    model_gwas_compare_simple<-final_compare_simple
  }else{
    new_row_partial_final<-data.frame(c(final_compare_partial$parameter[!final_compare_partial$parameter%in% model_gwas_compare_partial$parameter]))
    colnames(new_row_partial_final)[1]<-"parameter"
    rownames(new_row_partial_final)<-new_row_partial_final$parameter
    if(nrow(new_row_partial_final)>=1){
      new_row_partial_final[,2:ncol(model_gwas_compare_partial)]<-NA
      colnames(new_row_partial_final)[2:ncol(model_gwas_compare_partial)]<-colnames(model_gwas_compare_partial)[2:ncol(model_gwas_compare_partial)]
    }
    
    
    
    model_gwas_compare_partial_new<-rbind(model_gwas_compare_partial,new_row_partial_final)
    model_gwas_compare_partial<-left_join(model_gwas_compare_partial_new,final_compare_partial,by="parameter")
    
    
    new_row_full_final<-data.frame(c(final_compare_full$parameter[!final_compare_full$parameter%in% model_gwas_compare_full$parameter]))
    colnames(new_row_full_final)[1]<-"parameter"
    rownames(new_row_full_final)<-new_row_full_final$parameter
    if(nrow(new_row_full_final)>=1){
      new_row_full_final[,2:ncol(model_gwas_compare_full)]<-NA
      colnames(new_row_full_final)[2:ncol(model_gwas_compare_full)]<-colnames(model_gwas_compare_full)[2:ncol(model_gwas_compare_full)]
    }
    
    model_gwas_compare_full_new<-rbind(model_gwas_compare_full,new_row_full_final)
    model_gwas_compare_full<-left_join(model_gwas_compare_full_new,final_compare_full,by="parameter")
    
    
    
    new_row_simple_final<-data.frame(c(final_compare_simple$parameter[!final_compare_simple$parameter%in% model_gwas_compare_simple$parameter]))
    colnames(new_row_simple_final)[1]<-"parameter"
    rownames(new_row_simple_final)<-new_row_simple_final$parameter
    if(nrow(new_row_simple_final)>=1){
      new_row_simple_final[,2:ncol(model_gwas_compare_simple)]<-NA
      colnames(new_row_simple_final)[2:ncol(model_gwas_compare_simple)]<-colnames(model_gwas_compare_simple)[2:ncol(model_gwas_compare_simple)]
    }
    
    model_gwas_compare_simple_new<-rbind(model_gwas_compare_simple,new_row_simple_final)
    model_gwas_compare_simple<-left_join(model_gwas_compare_simple_new,final_compare_simple,by="parameter")
    
  }
  
  
}

model_gwas_compare_partial$na_gwas_sum<-rowSums(is.na(model_gwas_compare_partial%>%select(contains(c("na_sum")))))
model_gwas_compare_full$na_gwas_sum<-rowSums(is.na(model_gwas_compare_full%>%select(contains(c("na_sum")))))
model_gwas_compare_simple$na_gwas_sum<-rowSums(is.na(model_gwas_compare_simple%>%select(contains(c("na_sum")))))
saveRDS( model_gwas_compare_partial,paste(results_directory,"/gwas_meanAUC_partial.rds",sep=""))
saveRDS( model_gwas_compare_full,paste(results_directory,"/gwas_meanAUC_full.rds",sep=""))
saveRDS( model_gwas_compare_simple,paste(results_directory,"/gwas_meanAUC_simple.rds",sep=""))
sink()
#all r2=0.9 and p=0.005 here




library(stringr)
library(ggplot2)
for(i in c("partial","full","simple")){
  gwas_meanAUC<-readRDS(paste(results_directory,"/gwas_meanAUC_",i,".rds",sep=""))
  gwas_meanAUC$parameter<-sub("_standardised","",gwas_meanAUC$parameter)
  colnames(gwas_meanAUC)[seq(2,18,2)]<-sub("meanAUC_","",colnames(gwas_meanAUC)[seq(2,18,2)])
  
  gwas_meanAUC$h2<-sub("h2_\\s*", "",str_extract(gwas_meanAUC$parameter, "h2_\\s*\\d*\\.\\d+"))
  gwas_meanAUC$p<-sub("p_", "",str_extract(gwas_meanAUC$parameter, "p_\\d+\\.?\\d*e?.?\\d*"))
  gwas_meanAUC$p<-sub("e.", "e-",gwas_meanAUC$p)
  gwas_meanAUC$p<-sub("_", "",gwas_meanAUC$p)
  gwas_meanAUC$p<-as.numeric(gwas_meanAUC$p)
  gwas_meanAUC$h2<-as.numeric(gwas_meanAUC$h2)
  gwas_meanAUC$sparse<-factor(str_extract(gwas_meanAUC$parameter, "TRUE|FALSE"),levels = c("TRUE","FALSE"))
  
  for(j in 1:9){
    gwas_meanAUC[,2*j]<-ifelse(gwas_meanAUC[,2*j+1]>0,NA,gwas_meanAUC[,2*j])
  }
  
  gwas_meanAUC_up<-gwas_meanAUC[,c(1,seq(2,18,2),21:23)]
  
  
  dt_melt_standardised<-melt(gwas_meanAUC_up,c("p","h2","sparse","parameter"),value.name = "mean AUC")
  dt_melt_standardised<-dt_melt_standardised[is.na(dt_melt_standardised$`mean AUC`)==F,]
  dt_melt_inf<-dt_melt_standardised[dt_melt_standardised$parameter%in%c("prs_inf_meta","prs_inf_norm"),]
  dt_melt_standardised<-dt_melt_standardised[!dt_melt_standardised$parameter%in%c("prs_inf_meta","prs_inf_norm"),]
  dt_melt_standardised<-dt_melt_standardised[ as.numeric(dt_melt_standardised$h2)<=0.1,]
  dt_melt_standardised$h2<-as.factor(dt_melt_standardised$h2)
  p<-ggplot(data = dt_melt_standardised, aes(x=p,y=`mean AUC`,linetype=sparse,color=h2)) + 
    geom_line()+facet_wrap( ~ variable)+theme_bw()
  
  CairoPNG(filename =paste(results_directory,"/gwas_meanAUC_compare_",i,".png",sep=""),res=200,width = 25,height = 15,units = "cm" )
  print(p)
  dev.off()
  
  
  
  
}
