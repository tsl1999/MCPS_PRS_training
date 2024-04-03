
library(dplyr)
library(data.table)
library(xlsx)
## cross fold validation---------------------------------------------------------------
save_cvsplit<-function(data_in,folder_path,folder_number=1,
                       outcome="CAD_EPA",train_validation="train",
                       covar=c("SEX","AGE",paste("PC",1:7,sep=""))){
  
  suppressWarnings( dir.create(folder_path))
  train_GWAS<-data_in
  train_GWAS[,outcome]<-as.integer(train_GWAS[,outcome])
  case_df_train<-train_GWAS[train_GWAS[,outcome]==1,c("FID","IID")]
  pheno_df_train<-train_GWAS[,c("FID","IID",outcome)]
  covar_df_train<-train_GWAS[c("FID","IID",covar)]
  write.table(x=train_GWAS,file=paste(folder_path,"/table_",train_validation,"_",outcome,"_",folder_number,".txt",sep=""),
              sep="\t",quote=F,row.names=F,col.names=T)
  write.table(x=case_df_train,file=paste(folder_path,"/cases_",train_validation,"_",outcome,"_",folder_number,".txt",sep=""),
              sep="\t",quote=F,row.names=F,col.names=F)
  write.table(x=pheno_df_train,file=paste(folder_path, "/pheno_",train_validation,"_",outcome,"_",folder_number,".txt",sep=""),
              sep="\t",quote=F,row.names=F,col.names=T)
  write.table(x=covar_df_train,file=paste(folder_path, "/covar_",train_validation,"_",outcome,"_",folder_number,".txt",sep=""),
              sep="\t",quote=F,row.names=F,col.names=T)
  
}


cross_validation_split<-function(data_keep,fold=5,outcome="CAD_EPA",seed=1000,
                                 save=T,gwas=F,data_path=cvdata_path,
                                 covar=c("SEX","AGE",paste("PC",1:7,sep="")),full_data){
  set.seed(seed)
  ind = c(sample(rep(1:fold,each = nrow(data_keep)/fold)),
          sample(1:fold,nrow(data)%%fold,replace = F))
  data_keep$testing_fold<-ind
  cv_split<-list()
  cv_split_prop<-list()
  for(i in 1:fold){
    test_ID<-data_keep$IID[data_keep$testing_fold==i]
    train_ID<-data_keep$IID[!data_keep$IID%in%test_ID]
    length(unique(c(train_ID,test_ID)))
    train<-data_keep[data_keep$IID%in%train_ID,c(1:(ncol(data_keep)-1))]
    cat("training sample ",i, "case-control proportion ... \n")
    print(prop.table(table(train[,outcome]))*100)
    test<-data_keep[data_keep$IID%in%test_ID,c(1:(ncol(data_keep)-1))]
    cat("validation sample ",i, "case-control proportion ... \n")
    print(prop.table(table(test[,outcome]))*100)
    cv_split[[i]]<-list(train,test)
    names(cv_split[[i]])<-c("train","vallidation")
    names(cv_split)[i]<-paste("fold",i,sep="")
    train_validation_compare<-data.frame(rbind(paste(table(train[,outcome]),"(",prop.table(table(train[,outcome])),")",sep=""),
                                               paste(table(test[,outcome]),"(",prop.table(table(test[,outcome])),")",sep="")))
    
    rownames(train_validation_compare)<-c("training","validation")
    colnames(train_validation_compare)<-c("control",outcome)
    cv_split_prop[[i]]<-train_validation_compare
    train_full<-data[data$IID%in%train_ID,]#for prs testing
    test_full<-data[data$IID%in%test_ID,]
    if(save==T&gwas==T){
      suppressWarnings( dir.create(paste(data_path,outcome,sep="/")))
      folder_path<-paste(data_path,outcome,folder_number=i,sep="/")
      save_cvsplit(data_in=train,folder_path=folder_path,folder_number=i,
                   outcome=outcome,train_validation="gwas",
                   covar=covar)
      
      saveRDS(train,paste(folder_path,"/gwas_data.rds",sep=""))
      saveRDS(test_full,paste(folder_path,"/validation_data.rds",sep=""))
      saveRDS(train_full,paste(folder_path,"/gwas_data_full.rds",sep=""))
      write.table(test_full[,c("FID","IID")],paste(folder_path,"/validation_data.txt",sep=""),quote=F,row.names = F,sep="\t")
      if(i==1){
        append_i=FALSE
      }else{append_i=TRUE}
      
      write.xlsx(train_validation_compare,file=paste(data_path,outcome,
                                                     "fullcvdata_train_validation_proprtion.xlsx",sep="/"),
                 sheetName = paste("fold",i,sep=""),append = append_i,row.names=T)
    }else if(save==T&gwas==F){
      suppressWarnings( dir.create(paste(data_path,outcome,sep="/")))
      suppressWarnings( dir.create(paste(data_path,outcome,folder_number=i,sep="/")))
      folder_path<-paste(data_path,outcome,folder_number=i,sep="/")
      saveRDS(train,paste(folder_path,"/training_data.rds",sep=""))
      saveRDS(test_full,paste(folder_path,"/testing_data.rds",sep=""))
      saveRDS(train_full,paste(folder_path,"/training_data_full.rds",sep=""))
      write.table(test_full[,c("FID","IID")],paste(folder_path,"/validation_data.txt",sep=""),quote=F,row.names = F,sep="\t")
      if(i==1){
        append_i=FALSE
      }else{append_i=TRUE}
      
      write.xlsx(train_validation_compare,file=paste(data_path,outcome,
                                                     "fullcvdata_train_validation_proprtion.xlsx",sep="/"),
                 sheetName = paste("fold",i,sep=""),append = append_i,row.names=T)
    }
    
    
    
  }
  cv_data<-list(cv_split,cv_split_prop)
}



# 
# cross_validation_split<-function(data_keep,fold=5,outcome="CAD_EPA",seed=1000,
#                                  save=T,gwas=F,data_path=cvdata_path,
#                                  covar=c("SEX","AGE",paste("PC",1:7,sep="")),full_data){
#   cv_split<-list()
#   cv_split_prop<-list()
#   for(i in 1:fold){
#     set.seed(seed+i)
#     percent_out<-1/fold
#     percent_train<-1-percent_out
#     number_train<-round(nrow(data_keep)*percent_train)
#     train_ID<-sample(data_keep$IID,size=number_train,replace = F)
#     test_ID<-data_keep$IID[!data_keep$IID%in%train_ID]
#     length(unique(c(train_ID,test_ID)))
#     
#     train<-data_keep[data_keep$IID%in%train_ID,]
#     cat("training sample ",i, "case-control proportion ... \n")
#     print(prop.table(table(train[,outcome]))*100)
#     test<-data_keep[data_keep$IID%in%test_ID,]
#     cat("validation sample ",i, "case-control proportion ... \n")
#     print(prop.table(table(test[,outcome]))*100)
#     cv_split[[i]]<-list(train,test)
#     names(cv_split[[i]])<-c("train","vallidation")
#     names(cv_split)[i]<-paste("fold",i,sep="")
#     train_validation_compare<-data.frame(rbind(paste(table(train[,outcome]),"(",prop.table(table(train[,outcome])),")",sep=""),
#                                                paste(table(test[,outcome]),"(",prop.table(table(test[,outcome])),")",sep="")))
#     
#     rownames(train_validation_compare)<-c("training","validation")
#     colnames(train_validation_compare)<-c("control",outcome)
#     cv_split_prop[[i]]<-train_validation_compare
#     train_full<-data[data$IID%in%train_ID,]#for prs testing
#     test_full<-data[data$IID%in%test_ID,]
#     if(save==T&gwas==T){
#       suppressWarnings( dir.create(paste(data_path,outcome,sep="/")))
#       folder_path<-paste(data_path,outcome,folder_number=i,sep="/")
#       save_cvsplit(data_in=train,folder_path=folder_path,folder_number=i,
#                    outcome=outcome,train_validation="gwas",
#                    covar=covar)
#      
#       saveRDS(train,paste(folder_path,"/gwas_data.rds",sep=""))
#       saveRDS(test_full,paste(folder_path,"/validation_data.rds",sep=""))
#       saveRDS(train_full,paste(folder_path,"/gwas_data_full.rds",sep=""))
#       write.table(test_full[,c("FID","IID")],paste(folder_path,"/validation_data.txt",sep=""),quote=F,row.names = F,sep="\t")
#       if(i==1){
#         append_i=FALSE
#       }else{append_i=TRUE}
#       
#       write.xlsx(train_validation_compare,file=paste(data_path,outcome,
#                                                      "fullcvdata_train_validation_proprtion.xlsx",sep="/"),
#                  sheetName = paste("fold",i,sep=""),append = append_i,row.names=T)
#     }else if(save==T&gwas==F){
#       suppressWarnings( dir.create(paste(data_path,outcome,sep="/")))
#       suppressWarnings( dir.create(paste(data_path,outcome,folder_number=i,sep="/")))
#       folder_path<-paste(data_path,outcome,folder_number=i,sep="/")
#       saveRDS(train,paste(folder_path,"/training_data.rds",sep=""))
#       saveRDS(test_full,paste(folder_path,"/testing_data.rds",sep=""))
#       saveRDS(train_full,paste(folder_path,"/training_data_full.rds",sep=""))
#       write.table(test_full[,c("FID","IID")],paste(folder_path,"/validation_data.txt",sep=""),quote=F,row.names = F,sep="\t")
#       if(i==1){
#         append_i=FALSE
#       }else{append_i=TRUE}
#       
#       write.xlsx(train_validation_compare,file=paste(data_path,outcome,
#                                                 "fullcvdata_train_validation_proprtion.xlsx",sep="/"),
#                  sheetName = paste("fold",i,sep=""),append = append_i,row.names=T)
#     }
#     
#     
#     
#   }
#   cv_data<-list(cv_split,cv_split_prop)
# }
