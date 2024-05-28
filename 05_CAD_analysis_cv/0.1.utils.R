library(data.table)
library(ggplot2)
library(tidyr)
library(tidyverse)
library(dplyr)
library(pROC)
library(ROCR)
library(caret)
library(DescTools)
library(flextable)
library(forestploter)
library(grid)
library(Epi)
library(survival)
library(survminer)
"%&%" <- function(a,b) paste0(a,b)


#to extract confidence interval from model
ci<-function(x,number=95,roundup=3,row=2){
  actualci<-(100-(100-number)/2)/100
  ci_bound<-c(-qnorm(actualci,0,1),qnorm(actualci,0,1))
  coef<-summary(x)$coefficients[row,1]
  se<-summary(x)$coefficients[row,'Std. Error']
  ci<-exp(coef+ci_bound*se)
  c(round(exp(coef),roundup),round(ci,roundup))
}  

#to manually calculate ci
ci_manual<-function(x,se,number=95,roundup=3){
  actualci<-(100-(100-number)/2)/100
  ci_bound<-c(-qnorm(actualci,0,1),qnorm(actualci,0,1))
  ci<-c(x,x+ci_bound*se)
  ci
}

# Run Logistic regressions  -----------------------------------------


# create formula input for glm, will be the input for run_glm
# allow one interaction term with PRS, int=column_name
# create_glm_formula(adjustments=c(column_names),
#             outcome=column_name, prs_name=column_name)

#for more than one prs
create_glm_formula<-function(adjustments,outcome,prs_name,int=NULL){
  if(length(prs_name)>1){
    prs_name_in<-paste(prs_name,collapse="+")
  }else{prs_name_in=prs_name}
  
  if(is.null(adjustments)==T&is.null(int)==T){
    output_formula=formula(paste(outcome,"~",prs_name_in))
  }else if (is.null(adjustments)==F&is.null(int)==T){
    output_formula=formula(paste(outcome,"~",paste(prs_name_in,
                                                   paste(adjustments,collapse = "+"),sep="+"),sep=""))
  } else {
    output_formula=formula(paste(outcome,"~",paste(prs_name_in,
                                                   paste(adjustments,collapse = "+"),
                                                   paste(paste(int,prs_name,sep="*"),collapse="+"),
                                                   sep="+"),sep=""))
  }
  output_formula
  
}


# create_glm_formula<-function(adjustments,outcome,prs_name,int=NULL){
#   if(is.null(adjustments)==T&is.null(int)==T){
#     output_formula=formula(paste(outcome,"~",prs_name))
#   }else if (is.null(adjustments)==F&is.null(int)==T){
#     output_formula=formula(paste(outcome,"~",paste(prs_name,
#                                                    paste(adjustments,collapse = "+"),sep="+"),sep=""))
#   } else {
#     output_formula=formula(paste(outcome,"~",paste(prs_name,
#                                                    paste(adjustments,collapse = "+"),
#                                                    paste(paste(int,prs_name,sep="*"),collapse="+"),
#                                                    sep="+"),sep=""))
#   }
#   output_formula
#   
# }


# run_glm(data,adjustments=c(column_names),
#             outcome=column_name, prs_name=column_name)
run_glm<-function(data,adjustments,outcome,prs_name,int=NULL){
  cat("\n Modelling PRS... ",prs_name)
  model_output<-glm(create_glm_formula(adjustments,outcome,prs_name,int),
                    data=data,family=binomial(link='logit'))
  model_output
}



# input argument: data, adjustments column names and outcome column names
# if you wish to compute a roc curve, use roc=T, and specify a name using namew
# also specify graphs_path
# if you split the dataset into training and testing set, 
# set trainsplit=T and use train_data= and test_data=
# if you want to test for interaction for continuous exposures, use int=
# if you the exposure is continuous/categorical, use type="cont"/"cat" 
# all estimates will in default rounded up to 2 dp, change by dp=
# the function allow estimating for individual PRS or multiple PRSs
# use prs= to specify, if your PRSs follow the same naming rules, 
# you can just specify that rule, e.g. pgs=c("PGS")

# output include OR, AUC, pseudo-R2, case number, control number and p values
# if type = "cont", output is a table, if want to see se as well, set se=T

# if type = "cat", output is a list with 
# 1. list of estimates for plotting dose escalation plots -- see plot_FAR_gg
# 2. a table of AUC, pseudo-R2, case number, control number and p values

# example:
# model_output<-create_output_table_log(
#  trainsplit = F,data,adjustments=c("SEX"),outcome="prevalent_CHD_EPA",roc=F,
#  prs=c("PGS"),int="SBP")


create_output_table_log<-function(trainsplit=F,data,train_data=NULL,
                                  test_data=NULL,adjustments,outcome,namew=NULL,
                                  type="cont",roc=T,int=NULL,
                                  prs=c("PGS","custom"),se=F,dp=2,
                                  graphs_path=graphs_path){
  
  if(trainsplit==F){
    train_data=data
    test_data=data
  }else if(trainsplit==T){
    train_data=train_data
    test_data=test_data
  }
  train<-na.omit(train_data%>%select(IID,all_of(c(outcome,adjustments,int)),
                                     contains(c(prs))))
  test<-na.omit(test_data%>%select(IID,all_of(c(outcome,adjustments,int)),
                                   contains(c(prs))))
  
  
  
  start_column=which(colnames(train)%in%colnames(train%>%select(contains(prs))))
  
  if(type=="cont"){
    model_output_table<-data.frame(
      OR=NA,LR=NA,UR=NA,AUC=NA,AUC_LR=NA,AUC_UR=NA,Nagelkerke_PseudoR2=NA,
      lee_PseudoR2=NA,case_no=NA,control_no=NA,pval=NA,int_pval=NA,se=NA)
    
    if(roc==T){
      png(paste(graphs_path,"/logistic/AUCplot_cont","_",outcome,"_",namew,".png",
                sep=""),res=150,width = 15, height = 15,units = "cm")}
    
    
    for (i in 1:length(start_column)){
      
      model_output<-run_glm(data=train,adjustments,outcome,
                            colnames(train)[start_column[i]],int)
      pred<-predict(model_output,test,type='response')
      pred.obj<-prediction(pred,test[,outcome])
      perf.obj<-performance(pred.obj,"tpr","fpr")
      roc_prs<-roc(test[,outcome],pred)
      if(roc==T){
        if(i==1){
          plot(perf.obj,col=i)}else{plot(perf.obj,col=i,add=T)}}
      
      vr=runif(nrow(train),0,1)
      vsel=model_output$linear.predictors[model_output$y==0|vr<0.05]
      r2<-format(round(var(vsel)/(var(vsel)+pi^2/3),dp),nsmall=dp)
      
      
      auc_point<-auc(roc_prs)
      auc_ci<-format(round(ci.auc(test[,outcome],pred),dp),nsmall=dp)
      
      pval<-summary(model_output)$coefficients[,"Pr(>|z|)"][colnames(train)[start_column[i]]]
      pval<-format(signif(pval,dp),nsmall=dp)
      #pval<-as.character(signif(pval,digits=2))
      #pval = sub("e"," 10^",pval) 
      if(is.null(int)==F){
        int_pval<-summary(model_output)$coefficients[,"Pr(>|z|)"][
          nrow(summary(model_output)$coefficients)]
        int_pval<-format(signif(int_pval,dp),nsmall=dp)}else{int_pval=NA}
      or_ci<-format(ci(model_output,roundup=dp,row=colnames(train)[start_column[i]]),nsmall=dp)
      
      #pval<-ifelse(summary(model_output)$coefficients
      #[,"Pr(>|z|)"][2]<0.001,"<0.001",round(summary(model_output)$coefficients[,"Pr(>|z|)"][2],3))
      
      model_output_table[i,1:12]<-
        c(or_ci[1],or_ci[2],or_ci[3],auc_ci[2],auc_ci[1],auc_ci[3],
          format(round(PseudoR2(model_output,c("Nagelkerke")),dp),nsmall=dp),r2,
          table(train[,outcome])["1"],table(train[,outcome])["0"],pval,int_pval)
      
      rownames(model_output_table)[i]<-colnames(train)[start_column[i]]
      
      if(se==T){
        model_output_table$se[i]<-
          summary(model_output)$coefficients[,"Std. Error"][colnames(train)[start_column[i]]]
      }else{
        model_output_table<-model_output_table[,1:12]}
    }
    
    if(roc==T){
      abline(a=0,b=1,lty="dashed",col="gray")
      legend("bottomright",legend=c(paste(colnames(train)[
        start_column[1:length(start_column)]]," AUC=",
        round(as.numeric(model_output_table[,4]),3))),
        col=c(palette()[1:length(start_column)]),lty=1,cex=0.8)
      dev.off()}
    
    if(is.null(int)==F){model_output_table<-model_output_table}
    else{model_output_table<-model_output_table[,-c(12)]}
    
    output<-model_output_table
    
    output
    
  }else if(type=="cat"){
    model_output_table<-
      data.frame(AUC=NA,AUC_LR=NA,AUC_UR=NA,Nagelkerke_PseudoR2=NA,
                 lee_PseudoR2=NA,case_no=NA,control_no=NA)   
    model_estimate_list<-list()
    
    if (roc==T){
      png(paste(graphs_path,"/logistic/AUCplot_cat","_",
                outcome,"_",namew,".png",sep=""),
          res=150,width = 15, height = 15,units = "cm")}
    
    for (i in 1:length(start_column)){
      model_output<-run_glm(data=train,adjustments,outcome,
                            colnames(train)[start_column[i]],int=NULL)
      fl_a<-float(model_output,factor =colnames(train)[start_column[i]])
      model_estimate_output_table<-
        data.frame(estimate = round(exp(fl_a$coef), dp),
                   LR = round(exp(fl_a$coef - 1.96 * sqrt(fl_a$var)), dp),
                   UR = round(exp(fl_a$coef + 1.96 * sqrt(fl_a$var)), dp),
                   SE=fl_a$var,
                   case=table(train[,colnames(train)[start_column[i]]],
                              train[,outcome])[,2],
                   control=table(train[,colnames(train)[start_column[i]]],
                                 train[,outcome])[,1])
      
      model_estimate_output_table$category<-rownames(model_estimate_output_table)
      model_estimate_output_table<-model_estimate_output_table[,c(7,1:6)]
      colnames(model_estimate_output_table)[1]<-colnames(train)[start_column[i]]
      model_estimate_list[[i]]<-model_estimate_output_table
      pred<-predict(model_output,test,type='response')
      pred.obj<-prediction(pred,test[,outcome])
      perf.obj<-performance(pred.obj,"tpr","fpr")
      roc_prs<-roc(test[,outcome],pred)
      
      if(roc==T){
        if(i==1){
          plot(perf.obj,col=i)}else{plot(perf.obj,col=i,add=T)}}
      
      vr=runif(nrow(train),0,1)
      vsel=model_output$linear.predictors[model_output$y==0|vr<0.05]
      r2<-round(var(vsel)/(var(vsel)+pi^2/3),dp)
      auc_ci<-round(ci.auc(test[,outcome],pred),dp)
      
      model_output_table[i,]<-
        c(auc_ci[2],auc_ci[1],auc_ci[3],
          round(PseudoR2(model_output,c("Nagelkerke")),dp),r2,
          table(train[,outcome])["1"], table(train[,outcome])["0"])
      
      rownames(model_output_table)[i]<-colnames(train)[start_column[i]]
    }
    if(roc==T){
      abline(a=0,b=1,lty="dashed",col="gray")
      legend("bottomright",legend=c(paste(colnames(train)[
        start_column[1:length(start_column)]]," AUC=",
        round(as.numeric(model_output_table[,1]),3))),
        col=c(palette()[1:length(start_column)]),lty=1,cex=0.8)
      
      dev.off()  }
    output<-list(model_output_table,model_estimate_list)
  }
  
  
  output
  
}


create_output_table_log_multi<-function(trainsplit=F,data,train_data=NULL,
                                    test_data=NULL,adjustments,outcome,namew=NULL,
                                    type="cont",int=NULL,
                                    prs=c("prs"),dp=2){
  or_output<-list()
  model_output_table<-data.frame(matrix(ncol=8))
  colnames(model_output_table)[1:8]<-c("AUC",
                                       "AUC_LR","AUC_UR","Nagelkerke_PseudoR2","lee_PseudoR2","case_no","control_no","int_pval")
  for(j in 1:length(prs)){
    prs_in<-prs[[j]]
    
    if(trainsplit==F){
      train_data=data
      test_data=data
    }else if(trainsplit==T){
      train_data=train_data
      test_data=test_data
    }
    train<-na.omit(train_data%>%select(IID,all_of(c(outcome,adjustments,int)),
                                       contains(c(prs_in))))
    test<-na.omit(test_data%>%select(IID,all_of(c(outcome,adjustments,int)),
                                     contains(c(prs_in))))
    
    prs_col<-which(colnames(train)%in%colnames(train%>%select(contains(prs_in))))
    num_prs<-length(prs_col)
    model_or_output<-data.frame(matrix(ncol=5,nrow=num_prs))
    colnames(model_or_output)[1:5]<-c("OR","LR","UR","pval","se")
    
    for(i in 1:num_prs){
      rownames(model_or_output)[i]<-colnames(train)[prs_col[i]]
    }
    
    
    model_output<-run_glm(data=train,adjustments,outcome,
                          colnames(train)[prs_col],int)
    pred<-predict(model_output,test,type='response')
    pred.obj<-prediction(pred,test[,outcome])
    perf.obj<-performance(pred.obj,"tpr","fpr")
    roc_prs<-roc(test[,outcome],pred)
    
    vr=runif(nrow(train),0,1)
    vsel=model_output$linear.predictors[model_output$y==0|vr<0.05]
    r2<-format(round(var(vsel)/(var(vsel)+pi^2/3),dp),nsmall=dp)#lee's pseudo r2
    nagelkerke<-PseudoR2(model_output,c("Nagelkerke"))
    auc_point<-auc(roc_prs)
    auc_ci<-format(round(ci.auc(test[,outcome],pred),dp),nsmall=dp)
    
    
    if(is.null(int)==F){
      int_pval<-summary(model_output)$coefficients[,"Pr(>|z|)"][
        nrow(summary(model_output)$coefficients)]
      int_pval<-format(signif(int_pval,dp),nsmall=dp)}else{int_pval=NA}
    
    model_output_table[j,1:8]<-
      c(auc_ci[2],auc_ci[1],auc_ci[3],
        format(round(nagelkerke,dp),nsmall=dp),r2,
        table(train[,outcome])["1"],table(train[,outcome])["0"],int_pval)
    rownames(model_output_table)[j]<-names(prs)[j]
    
    for (i in 1:num_prs){
      
      pval<-summary(model_output)$coefficients[,"Pr(>|z|)"][colnames(train)[prs_col[i]]]
      pval<-format(signif(pval,dp),nsmall=dp)
      se<-summary(model_output)$coefficients[,"Std. Error"][colnames(train)[prs_col[i]]]
      or_ci<-format(ci(model_output,roundup=dp,row=colnames(train)[prs_col[i]]),nsmall=dp)
      model_or_output[i,1:5]<-
        c(or_ci[1],or_ci[2],or_ci[3],pval,se)
    }
    
    
    if(is.null(int)==F){model_output_table<-model_output_table
    }else{model_output_table<-model_output_table[,-c(8)]}
    or_output[[j]]<-model_or_output
    names(or_output)[j]<-names(prs)[j]
    
    
    
  }
  model_output_list<-list(model_output_table,or_output)
  names(model_output_list)<-c("model_auc","odds_ratio")
  model_output_list
}



# Run cox regressions ------------------------------------------------------

#create_surv_formula(adjustments=adjustments,outcome=outcome,prs_name="PGS000011")

create_surv_formula<-function(adjustments,strata=NULL,outcome,prs_name,int=NULL,
                              interval=F,time=NULL){
  if(interval==F){
    surv_formula<-paste("Surv(time_in,time_out,",outcome,")",sep="")
    
  }else{
    surv_formula<-paste("Surv(",time,",",outcome,")",sep="")
  }
  
  
  if(is.null(int)==T){
    int_input<-NULL
  }else{int_input<-paste(paste(int,prs_name,sep="*"),collapse="+") }
  
  
  if(is.null(adjustments)==T&is.null(strata)==T){
    output_formula=
      formula(paste(surv_formula,"~",paste(c(prs_name,int_input),collapse = "+"),
                    sep=""))
  }else if (is.null(adjustments)==F&is.null(strata)==T){
    output_formula=
      formula(paste(surv_formula,"~",paste(prs_name,
                                           paste(adjustments,collapse = "+"),int_input,sep = "+"),sep=""))
  }else {output_formula=
    formula(paste(surv_formula, "~",
                  paste(paste(c(prs_name,adjustments,int_input),collapse = "+"),
                        "+ strata(",strata,")",sep = ""),sep=""))}  
  output_formula
}


#run_cox(data=data,adjustments=adjustments,outcome=outcome,prs_name=prs_name)
run_cox<-function(data,adjustments,strata=NULL,outcome,prs_name,int=NULL,
                  interval=F,time=NULL){
  cat("\n Modelling PRS ...",prs_name)
  model_output<-
    coxph(create_surv_formula(adjustments,strata,outcome,prs_name,int,
                              interval,time),data = data)
  model_output
}



# input argument: data, adjustments column names and outcome column names
# if you split the dataset into training and testing set, 
# set trainsplit=T and use train_data= and test_data=
# if you want to test for interaction for continuous exposures, use int=
# if you the exposure is continuous/categorical, use type="cont"/"cat" 
# all estimates will in default rounded up to 2 dp, change by dp=
# the function allow estimating for individual PRS or multiple PRSs
# use prs= to specify, if your PRSs follow the same naming rules, 
# you can just specify that rule, e.g. pgs=c("PGS")
# if want to check proportional hazard assumptions, us ph=T
#specify graphs_path if you want to save propotional hazard plot

# output include HR,Harrell's C index ,case number, control number and p values
# if type = "cont", output is a table, if want to see se as well, set se=T

# if type = "cat", output is a list with 
# 1. list of estimates for plotting dose escalation plots -- see plot_FAR_gg
# 2. a table of Harrell's C index,  case number, control number and p values

# example:
# model_output<-create_output_table_cox(
#  trainsplit = F,data,adjustments=c("SEX"),outcome="prevalent_CHD_EPA",roc=F,
#  prs=c("PGS"),int="SBP")


create_output_table_cox<-function(trainsplit=F,data,train_data=NULL,
                                  test_data=NULL,adjustments,strata=NULL,
                                  outcome,namew=NULL,type="cont",ph=F,
                                  prs=c("PGS","custom"),int=NULL,dp=2,
                                  graphs_path=graphs_path,se=F,
                                  interval=F,time=NULL){
  
  if(trainsplit==F){
    train_data=data
    test_data=data
  }else if(trainsplit==T){
    train_data=train_data
    test_data=test_data
  }
  
  train<-drop_na(train_data%>%select(IID,time_in,time_out,
                                     all_of(c(outcome,adjustments,strata,int)),
                                     contains(c(prs))))
  test<-drop_na(test_data%>%select(IID,time_in,time_out,
                                   all_of(c(outcome,adjustments,strata,int)),
                                   contains(c(prs))))
  
  
  start_column=which(colnames(train)%in%colnames(train%>%select(contains(prs))))
  
  if(type=="cont"){
    
    model_output_table<-data.frame(HR=NA,LR=NA,UR=NA,AUC=NA,AUC_LR=NA,
                                   AUC_UR=NA,case_no=NA,control_no=NA,pval=NA,
                                   int_pval=NA,se=NA)
    
    for (i in 1:length(start_column)){
      
      
      model_output<-run_cox(data = train,adjustments,strata,outcome,
                            prs_name=colnames(train)[start_column[i]],int=int,
                            interval=interval,time=time)
      
      if (ph==T){
        dir.create(paste(graphs_path,"/cox/",
                         colnames(train)[start_column[i]],sep=""))
        jpeg(paste(graphs_path,"/cox/",colnames(train)[start_column[i]],"/",
                   colnames(train)[start_column[i]],"_Schoenfeld_residual",
                   type,namew,".png",sep=""),width = 800, height = 600)
        cox.zph.fit <- cox.zph(model_output)
        p<-ggcoxzph(cox.zph.fit,font.main = 8)
        print(p)
        dev.off()
      } # plot schoenfeld residuals
      
      hr_ci<-format(round(summary(model_output)$conf.int[colnames(train)[start_column[i]],
                                                         c(1,3:4)],2),nsmall=dp)
      c_index<-format(round(ci_manual(x=summary(model_output)$concordance[1],
                                      se=summary(model_output)$concordance[2]),dp),nsmall=dp)
      case_no<-sum(train[,outcome]==1)
      case_id<-unique(train[train[,outcome]==1,"IID"])
      control<-train[!train$IID%in%case_id,]
      control_no<-length(unique(control[control[,outcome]==0,"IID"]))
      pval<-summary(model_output)$coefficients[
        colnames(train)[start_column[i]],"Pr(>|z|)"]
      pval<-format(signif(pval,dp),nsmall=dp)
      
      if(is.null(int)==F){
        int_pval<-summary(model_output)$coefficients[,"Pr(>|z|)"][
          nrow(summary(model_output)$coefficients)]
        int_pval<-format(signif(int_pval,dp),nsmall=dp)}else{int_pval=NA}
      
      model_output_table[i,1:10]<-
        c(hr_ci[1],hr_ci[2],hr_ci[3],c_index[1],c_index[2],c_index[3],
          case_no,control_no,pval,int_pval)
      
      rownames(model_output_table)[i]<-colnames(train)[start_column[i]]
      
      if(se==T){
        model_output_table$se[i]<-summary(model_output)$coefficients[colnames(train)[start_column[i]],]["se(coef)"]
      }else{model_output_table<-model_output_table[,1:10]}
      
      if(is.null(int)==F){model_output_table<-model_output_table
      }else{model_output_table<-model_output_table[,-c(10)]}
    }
    
    
    
    output<-model_output_table
    
    
  }else if(type=="cat"){
    model_output_table<-data.frame(AUC=NA,AUC_LR=NA,AUC_UR=NA,
                                   case_no=NA,control_no=NA)
    model_estimate_list<-list()
    
    for (i in 1:length(start_column)){
      model_output<-run_cox(data = train,adjustments,strata,outcome,
                            prs_name=colnames(train)[start_column[i]],int=NULL,
                            interval=interval,time=time)
      
      fl_a<-float(model_output,factor =colnames(train)[start_column[i]])
      model_estimate_output_table<-data.frame(
        estimate = round(exp(fl_a$coef), dp),
        LR = round(exp(fl_a$coef - 1.96 * sqrt(fl_a$var)), dp),
        UR = round(exp(fl_a$coef + 1.96 * sqrt(fl_a$var)), dp),
        SE=fl_a$var,case=NA,control=NA)
      
      for (j in 1: length(levels(train[,colnames(train)[start_column[i]]]))){
        cat_only_row<-train[train[,colnames(train)[start_column[i]]]==j,]
        case_id<-unique(cat_only_row[cat_only_row[,outcome]==1,"IID"])
        case_no<-sum(cat_only_row[,outcome]==1)
        control<-cat_only_row[!cat_only_row$IID%in%case_id,]
        control_no<-length(unique(control[control[,outcome]==0,"IID"]))
        model_estimate_output_table$case[j]<-case_no
        model_estimate_output_table$control[j]<-control_no
      }
      
      model_estimate_output_table$category<-rownames(model_estimate_output_table)
      model_estimate_output_table<-model_estimate_output_table[,c(7,1:6)]
      colnames(model_estimate_output_table)[1]<-colnames(train)[start_column[i]]
      model_estimate_list[[i]]<-model_estimate_output_table
      
      
      if (ph==T){
        jpeg(paste(graphs_path,"/cox/",sub("_cat","",
                                           colnames(train)[start_column[i]]),"/",
                   colnames(train)[start_column[i]],"_Schoenfeld_residual",
                   type,namew,".png",sep=""),width = 800, height = 600)
        cox.zph.fit <- cox.zph(model_output)
        p<-ggcoxzph(cox.zph.fit,font.main = 8)
        print(p)
        dev.off()
      }
      
      c_index<-format(round(ci_manual(x=summary(model_output)$concordance[1],
                                      se=summary(model_output)$concordance[2]),dp),nsmall=dp)
      case_no<-sum(train[,outcome]==1)
      case_id<-unique(train[train[,outcome]==1,"IID"])
      
      control<-train[!train$IID%in%case_id,]
      control_no<-length(unique(control[control[,outcome]==0,"IID"]))
      
      model_output_table[i,]<-c(c_index[1],c_index[2],c_index[3],
                                case_no,control_no)
      rownames(model_output_table)[i]<-colnames(train)[start_column[i]]
      
    }
    output<-list(model_output_table,model_estimate_list) 
  }  
  output
  
}

## check linearity assumption----------------------------
plot_martingale<-function(variable,outcome,include="all",save=NULL){
  
  data_in<-data%>%select(IID,variable,time_in,time_out,outcome)
  data_in<-na.omit(data_in)
  if(include=="all"){
    formula_in<-formula(paste("Surv(time_in,time_out, ",outcome,")~"
                              ,paste(variable,"+log(",variable,")+ I(",variable,"^2",")+sqrt(",variable,")",sep=""),sep=""))
  }else if(include=="linear") {
    formula_in<-formula(paste("Surv(time_in,time_out, ",outcome,")~",variable,sep=""))
  }
  model<-coxph(formula_in, data = data_in)
  jpeg(paste(graphs_path,save,"/Martingale_residual_",variable,".png",sep=""),width = 800, height = 600)
  p<-ggcoxfunctional(model, data = data_in, point.col = "blue", point.alpha = 0.5,
                     title = paste("Martingale residules for",variable,sep=" "))
  print(p)
  dev.off()}

# Run stratified analysis------------------------------------------------------


run_stratified<-function(data,strata_in,outcome,adjustment,
                         se=T,show_int=F,model="logistic",model_strata=NULL,
                         prs=c("PGS","custom"),dp=2){
  all_strata_outcome<-list()
  for(i in 1: length(strata_in)){
    strata_var<-strata_in[i]
    print(strata_var)
    var_in<-ifelse(class(data[,strata_var])%in%c("integer","numeric"),
                   paste(strata_var,"_cut",sep=""),strata_var)
    var<-data[,var_in]
    strata_outcome_table<-list()
    for(j in 1:length(levels(var))){
      print(levels(var)[j])
      data_stratified<-data[var==levels(var)[j],,]
      print(table(data_stratified[,outcome]))
      adjustments<-adjustment[!adjustment%in%c(strata_var)]
      if(sum(length(adjustment)==1&adjustment==strata_in)==1){
        adjustments=NULL
      }
      
      if(model=="logistic"){
        print("Running logistic regression...")
        model_output_stratify<-create_output_table_log(
          trainsplit = F,data_stratified,adjustments=adjustments,
          outcome=outcome,namew=paste(strata_var,levels(var)[j],sep="_"),
          roc = F,se=se,prs=prs,dp=dp)
      }else if (model=="cox"){
        print("Running cox regression...")
        
        model_output_stratify<-create_output_table_cox(
          trainsplit = F,data=data_stratified,adjustments=adjustments,
          outcome=outcome,namew=paste(strata_var,levels(var)[j],sep="_"),
          se=se,prs=prs,dp=dp,strata=model_strata)
      }
      
      
      strata_outcome_table[[j]]<-model_output_stratify
      names(strata_outcome_table)[j]<-levels(var)[j]
      
    }
    if(show_int==T){
      
      if(model=="logistic"){
        print("Running logistic regression for intervention...")
        strata_outcome_table[[length(levels(var))+1]]<-create_output_table_log(
          trainsplit = F,data,adjustments=adjustment,
          outcome=outcome,namew="overall",roc = F,se=se,int = var_in,dp=dp,
          prs=prs)
        
      }else if (model=="cox"){
        print("Running cox regression for intervention...")
        strata_outcome_table[[length(levels(var))+1]]<-create_output_table_cox(
          trainsplit = F,data,adjustments=adjustment,
          outcome=outcome,namew="overall",se=se,int = var_in,dp=dp,
          prs=prs,strata=model_strata)
      }
      names(strata_outcome_table)[length(levels(var))+1]<-"Interaction"
    }
    
    all_strata_outcome[[i]]<-strata_outcome_table
    names(all_strata_outcome)[i]<-strata_var
  }
  
  if (model=="logistic"){
    print("Running logistic regression for overall...")
    all_strata_outcome[[length(strata_in)+1]]<-create_output_table_log(
      trainsplit = F,data,adjustments=adjustment,
      outcome=outcome,namew="overall",roc = F,se=se,dp=dp,
      prs=prs)
  } else if (model=="cox"){
    print("Running cox regression for overall...")
    all_strata_outcome[[length(strata_in)+1]]<-create_output_table_cox(
      trainsplit = F,data,adjustments=adjustment,
      outcome=outcome,namew="overall",se=se,dp=dp,
      prs=prs,strata=model_strata)
  }
  names(all_strata_outcome)[length(strata_in)+1]<-"Overall"
  
  all_strata_outcome
  
  
}




# Visualiation-----------------------------------------------------------------
## for both cox and logistic outputs
# default is logistic

## Forest plot showing for continuous PRSs-------------------------------------

# This is to generate the forestplot format dataset to be input into forestplotr
# The function allows more than one model output results, 
# use tables=list (model_output), model_output is the results from creat_mode_output_table
# specify the name for each model using model_name
# The default is for logistic regression (OR), is used cox, use or_hr="HR"
# normally the prs_name for estimates are ID, which can be confusing,
# if want to specify prs names further, use show_prsname=T, and specify names 
# in prs_formal_name=
# if want to show interaction results, use int=T
# default dp is 2, to change use dp=


## example:
# forest_table<-generate_forest_table(
#  tables=list(model_output_all),
#  model_name = c(""),or_hr = "OR",show_pgsname = T, 
#  pgs_formal_name=pgs_formal_name)


generate_forest_table<-function(tables,model_name,or_hr="OR",show_prsname=F,
                                prs_formal_name=NULL,int=NULL,dp=2){
  hr_ci<-NA
  if (is.null(int)==T){
    forest_table<-data.frame(subgroup=NA,case_no=NA,control_no=NA,
                             OR=NA,LR=NA,UR=NA,hr_ci=NA,auc_ci=NA,pval=NA)
  }else{
    forest_table<-data.frame(subgroup=NA,case_no=NA,control_no=NA,
                             OR=NA,LR=NA,UR=NA,hr_ci=NA,auc_ci=NA,pval=NA,
                             int_pval=NA)
  }
  n_table<-length(tables) # allow multiple models results to be aligned together
  name<-c(rep(NA,n_table))
  
  for (i in 1:n_table){
    name[i]<-paste("\U{00A0}\U{00A0}",model_name[i],sep="")
  }
  
  model_list<-tables
  nprs<-nrow(model_list[[1]])
  for (i in 1:nprs){
    if (show_prsname==T){
      prs_formal_name_in<-prs_formal_name[names(prs_formal_name)%in%rownames(model_output)]
      forest_table<-rbind(forest_table,
                          c(prs_formal_name_in[i],rep(" ",ncol(forest_table)-1)))
    }else{
      forest_table<-rbind(forest_table,
                          c(rownames(model_list[[1]])[i],
                            rep(" ",ncol(forest_table)-1)))}
    for (j in 1:n_table){
      if(show_prsname==T){
        row<-rownames(model_list[[j]])[
          names(prs_formal_name_in)[i]==rownames(model_list[[j]])]
      }else{
        row<-rownames(model_list[[j]])[i]
      }
      
      row_computing<- model_list[[j]][row,]
      hr_ci<-paste(format(row_computing[1],nsmall=dp),
                   "(",format(row_computing[2],nsmall=dp),
                   "-",format(row_computing[3],nsmall=dp),")",sep="")
      auc_ci<-paste(format(row_computing[4],nsmall=dp),
                    "(",format(row_computing[5],nsmall=dp),
                    "-",format(row_computing[6],nsmall=dp),")",sep="")
      
      if(is.null(int)==T){
        row_input<-unlist(c(name[j],model_list[[j]][row,
                                                    c("case_no","control_no",or_hr,"LR","UR")],
                            hr_ci,auc_ci,model_list[[j]][i,c("pval")]))
      }else if (is.null(int)==F){row_input<-unlist(c(
        name[j],model_list[[j]][row,c("case_no","control_no",or_hr,"LR","UR")],
        hr_ci,auc_ci,model_list[[j]][i,c("pval","int_pval")]))  
      }
      forest_table<-rbind(forest_table,row_input,make.row.names=F)
    }
    
  }
  forest_table<-forest_table[2:nrow(forest_table),]
  forest_table$" "<- paste(rep(" ", 40), collapse = " ")
  if(is.null(int)==T){
    colnames(forest_table)<-c("PRS name","Number of cases", 
                              "Number of controls", "estimate","LR","UR"," ",
                              "AUC (95%CI)","p-value","   ")
  }else{
    colnames(forest_table)<-c("PRS name","Number of cases", 
                              "Number of controls", "estimate","LR","UR"," ",
                              "AUC (95%CI)","p-value",
                              paste("Interaction with",int,"(p-value)" ,
                                    sep=" "),"   ")}
  
  forest_table
}

## stratified forest table------------------------
stratified_analysis_table<-function(all_strata_outcome, all_name,strata_in,
                                    data,model="logistic",show_int=F){
  estimate<-ifelse(model=="logistic","OR","HR")
  prs=which(colnames(data)%in%colnames(data%>%select(contains(rownames(all_strata_outcome[length(all_strata_outcome)][[1]])))))
  
  forest_table_list<-list()
  for (i in 1:length(prs)){
    prsname<-colnames(data)[prs[i]]
    if(show_int==F){
      forest_table<-data.frame(Variable=NA,case_no=NA,control_no=NA,
                               OR=NA,LR=NA,UR=NA,hr_ci=NA,auc_ci=NA,pval=NA)
    }else{
      forest_table<-data.frame(Variable=NA,case_no=NA,control_no=NA,
                               OR=NA,LR=NA,UR=NA,hr_ci=NA,auc_ci=NA,pval=NA,
                               int_pval=NA)
    }
    
    
    for(j in 1:(length(all_strata_outcome)-1)){
      forest_table<-rbind(forest_table,c(all_name[j],rep(" ",
                                                         ncol(forest_table)-1)))
      strata_var<-strata_in[j]
      var_in<-ifelse(class(data[,strata_var])%in%c("integer","numeric"),
                     paste(strata_var,"_cut",sep=""),strata_var)
      var_level<-levels(data[,var_in])
      strata_outcome<-all_strata_outcome[[j]]
      if(show_int==T){
        forest_table$int_pval[nrow(forest_table)]<-strata_outcome[[length(var_level)+1]][  prsname,"int_pval"]
      }
      
      for(k in 1:length(var_level)){
        
        
        stratified_var<-var_level[k]
        strata_outcome_row<-strata_outcome[[k]][prsname,]
        hr_ci<-paste(format(strata_outcome_row[1],nsmall=3),"(",
                     format(strata_outcome_row[2],nsmall=3),"-",
                     format(strata_outcome_row[3],nsmall=3),")",sep="")
        auc_ci<-paste(format(strata_outcome_row[4],nsmall=3),"(",
                      format(strata_outcome_row[5],nsmall=3),"-",
                      format(strata_outcome_row[6],nsmall=3),")",sep="")
        row_input<-unlist(c(paste("\U{00A0}\U{00A0}",stratified_var),
                            strata_outcome_row[c("case_no","control_no",estimate,"LR","UR")],
                            hr_ci,auc_ci,strata_outcome_row[c("pval")]))
        if(show_int==T){
          row_input=c(row_input," ")}
        
        
        
        forest_table<-rbind(forest_table,row_input,make.row.names=F)
        
      }
      
      
    }
    strata_outcome<-all_strata_outcome[[length(all_strata_outcome)]]
    strata_outcome_row<-strata_outcome[prsname,]
    hr_ci<-paste(format(strata_outcome_row[1],nsmall=3),"(",
                 format(strata_outcome_row[2],nsmall=3),"-",
                 format(strata_outcome_row[3],nsmall=3),")",sep="")
    auc_ci<-paste(format(strata_outcome_row[4],nsmall=3),"(",
                  format(strata_outcome_row[5],nsmall=3),"-",
                  format(strata_outcome_row[6],nsmall=3),")",sep="")
    row_input<-unlist(c("Overall",strata_outcome_row[c("case_no","control_no",estimate,"LR","UR")],
                        hr_ci,auc_ci,strata_outcome_row[c("pval")]))
    
    if(show_int==T){
      row_input=c(row_input,NA)}
    forest_table<-rbind(forest_table,row_input,make.row.names=F)
    forest_table<-forest_table[2:nrow(forest_table),]
    forest_table$" "<- paste(rep(" ", 40), collapse = " ")
    if(show_int==T){
      colnames(forest_table)<-c(prsname,"CAD cases", "CAD controls", 
                                "estimate","LR","UR"," ","AUC (95%CI)",
                                "p-value","Interaction p-value","   ")}else{
                                  colnames(forest_table)<-c(prsname,"CAD cases", "CAD controls", 
                                                            "estimate","LR","UR"," ","AUC (95%CI)",
                                                            "p-value","   ")}
    forest_table_list[[i]]<-forest_table
    
    
  }
  forest_table_list
}




# To plot forest plot, the input will be the output from the generate_forest_table
# Specify the column you want to show on the plot and their order by col_input=
# the default is still OR, to change it to HR, use hr_or="HR"
# default theme can be changed using tm above
# event_name is the outcome you are testing, e.g. CAD
# to input footnote, use footnote_in=
# specify the graphs_path and name to be saved in 


## example:
#p<-plot_forest(forest_table = forest_table,hr_or = "OR", 
#footnote_in = "footnote",
#event_name="CAD",col_input=c(1:3,10,7,9,8),graphs_path="test/test", name="test")

plot_forest<-function(forest_table,hr_or="OR",col_input=c(1:3,10,7,9,8),
                      footnote_in=NULL,event_name,
                      fontsize=7,ci_col=c("black"),
                      title=NULL,title_cex=0.5,multipleprs=T,summary=F){
  
  tm <- forest_theme(base_size = fontsize,
                     core = list(bg_params=list(fill = c("white"))),
                     summary_col = "black",
                     refline_lty = "solid",
                     ci_pch = 15,
                     ci_col = ci_col,
                     footnote_col = "black",
                     footnote_cex = 0.9,
                     vertline_lwd = 1,
                     vertline_lty = "dashed",
                     vertline_col = "grey20",
                     xaxis_cex=0.9,
                     ci_lty =1 ,
                     ci_lwd = 1,
                     ci_Theight = 0.2,
                     title_cex = title_cex)
  
  forest_table_in<-forest_table[,col_input]
  xlim=c(0.9,round(as.numeric(max(forest_table$UR)),2)+0.1)
  ticks_at=seq(0.9,round(as.numeric(max(forest_table$UR)),2)+0.1,by=0.1)
  ci_column<-which(colnames(forest_table_in)%in%colnames(
    forest_table%>%select(contains("   "))))
  if(summary==F){
    p <- forest(forest_table_in,
                est = as.numeric(forest_table$estimate),
                lower = as.numeric(forest_table$LR), 
                upper = as.numeric(forest_table$UR),
                ci_column = ci_column,
                ref_line = 1,
                arrow_lab = c(paste("Lower risk of",event_name), 
                              paste("Higher risk of",event_name)),
                xlim = xlim,
                ticks_at = ticks_at,
                footnote = ifelse(is.null(footnote_in)==F,
                                  paste("\n\n\n\n\n\n\n\n\n",footnote_in)," "),
                theme=tm,
                title = title)
  }else{
    p <- forest(forest_table_in,
                est = as.numeric(forest_table$estimate),
                lower = as.numeric(forest_table$LR), 
                upper = as.numeric(forest_table$UR),
                ci_column = ci_column,
                ref_line = 1,
                arrow_lab = c(paste("Lower risk of",event_name), 
                              paste("Higher risk of",event_name)),
                is_summary = c(rep(FALSE, nrow(forest_table_in)-1), TRUE),
                vert_line = c(as.numeric(forest_table_in[forest_table_in[,1]=="Overall",]$estimate)),
                xlim = xlim,
                ticks_at = ticks_at,
                footnote = ifelse(is.null(footnote_in)==F,
                                  paste("\n\n\n\n\n\n\n\n\n",footnote_in)," "),
                theme=tm,
                title = title)
    
  }
  
  
  p <- add_border(p, 
                  part = "header", 
                  row = 1,
                  col = 1:length(col_input), gp = gpar(lwd = 1))
  
  nprs<-length(unique(forest_table$`PRS name`))-1
  if(multipleprs==T){
    p<- edit_plot(p, row = c(seq(1,nrow(forest_table),
                                 by=nrow(forest_table)/nprs)), col=1,
                  gp = gpar(fontface = "bold"))
  }
  
  
  p <- add_text(p, text = paste(hr_or, "per SD (95% CI)",sep=" "),
                part = "header", 
                col = c(ci_column,ci_column+1),row=1,
                gp = gpar(fontface="bold",fontsize=fontsize))
  
  p
  
  
  
  
}

plot_forest_stratified<-function(forest_table_list,all_strata_outcome,
                                 fontsize=7,ci_col=c("black"),hr_or="OR",
                                 footnote_in=NULL,event_name,
                                 title=NULL,graph_name,graphs_path,
                                 title_cex = 0.5,show_int=F){
  
  for (i in 1:length(forest_table_list)){
    forest_input<-forest_table_list[[i]]
    max_ur<-max(as.numeric(forest_input$UR),na.rm=T)
    min_ur<-min(as.numeric(forest_input$LR),na.rm=T)
    
    if(length(title)>1){
      title_in<-title[i]
    }else{title_in<-title}
    
    if(show_int==T){
      col_input=c(1:3,11,7,9,8,10)
    }else{
      col_input=c(1:3,10,7,9,8)
    }
    
    p<-plot_forest(forest_table = forest_input,hr_or = hr_or, 
                   footnote_in = footnote_in,
                   event_name=event_name,col_input=col_input,
                   fontsize = fontsize,title=title_in,
                   title_cex = title_cex,multipleprs = F)
    
    
    
    
    row_highlight<-NA
    for(j in 1:length(all_strata_outcome)){
      if(j==1){
        row_highlight[j]<-1
      }else{
        row_highlight[j]<-row_highlight[j-1]+
          length(all_strata_outcome[[j-1]])
      }
    }
    
    
    
    p<- edit_plot(p, row = row_highlight, col=1,
                  gp = gpar(fontface = "bold"))
    
    
    p <- edit_plot(p, col = 1:7, 
                   row = nrow(forest_input), 
                   which = "background", 
                   gp = gpar(fill = "#f6eff7"))
    a<-get_wh(p,unit = "cm")+2
    
    png(paste(graphs_path,"/",graph_name,"_",colnames(forest_input)[1],".png",sep=""), res = 200, width = a[1], height = a[2], units = "cm")
    print(p)
    dev.off()
    
    
  }
}

## Dose escalation plot for categorical PRS groups -----------------------------

# Using floating absolute risk (FAR)

get_FAR_input<-function(model_output,data){
  model_estimate_in<-data.frame(model_output)
  prs_name<-sub("_cat","",colnames(model_estimate_in)[1])
  model_prs_reading<-data%>%select(contains(prs_name))
  model_prs_reading_decile<-data.frame(decile=NA,avg=NA)
  model_prs_reading_decile[1:length(levels(model_prs_reading[,2])),
                           1]<-levels(model_prs_reading[,2])
  for (k in 1:length(levels(model_prs_reading[,2]))) {
    model_prs_reading_decile[k,2]<-
      mean(model_prs_reading[model_prs_reading[,2]==model_prs_reading_decile[k,1],1])
  }
  
  colnames(model_prs_reading_decile)[1]<-prs_name
  model_estimate<-merge(model_estimate_in,model_prs_reading_decile,
                        by.x=colnames(model_estimate_in)[1],
                        by.y=colnames(model_prs_reading_decile)[1])
}




plot_FAR<-function(model_estimate,or_hr="OR",xlab=NULL,title=NULL, case=T, 
                   estimate=T,ylab=NULL,
                   ymin_input=NULL,ymax_input=NULL,
                   title_size=7){
  
  
  if(is.null(ymin_input)==T&is.null(ymax_input)==T){
    ymin<-min(model_estimate$LR)
    ymax<-max(model_estimate$UR)
  }else{
    ymin=ymin_input
    ymax=ymax_input
  }
  
  
  p<-ggplot(model_estimate, aes(x=avg, y=estimate)) + 
    geom_smooth(linetype="dashed",color="gray",method = "lm", se = FALSE) +
    geom_point(aes(size=0.0001/SE),shape=15)+
    geom_pointrange(aes(ymin=LR, ymax=UR), 
                    position=position_dodge(0.05),shape=15)+
    theme_classic()+
    theme(legend.position = "none",
          plot.title = element_text(size = title_size, face = "bold"),
          axis.title.y = element_text(face="bold"))+
    scale_fill_discrete(name = " ")+
    scale_y_continuous(trans = "log",limits = c(ymin-0.1,ymax+0.1), 
                       breaks = seq(0.9, ymax,0.2))+
    xlab(xlab)+
    scale_x_continuous(breaks=c(model_estimate$avg),
                       labels=model_estimate[,1],limits = c(-1.8,1.8))
  
  
  if(case==T){
    p<-p+annotate("text",x=model_estimate$avg, y=model_estimate$LR-0.05, 
                  label=model_estimate$case,size=3)}
  if(estimate==T){
    p<-p+annotate("text",x=model_estimate$avg, y=model_estimate$UR+0.05, 
                  label=model_estimate$estimate,size=3)}
  
  
  if(is.null(ylab)==T){
    p<-p+ylab(paste(or_hr, "(95%CI)"))
  }else(
    p<-p+ylab(ylab)
  )
  
  if(is.null(title)==T){
    p<-p+ggtitle(colnames(model_estimate)[1])
  }else{
    p<-p+ggtitle(title)
  }
  p
}

get_FAR_input_strata<-function(model_output_list,strata,data,name=NULL){
  
  strata_list<-levels(data[,strata])
  no_strata<-length(strata_list)
  interval<-length(model_output_list)/no_strata
  output_all<-list()
  for(i in 1:interval){
    model_estimate_all<-data.frame()
    model_prs_reading_decile_all<-data.frame()
    for(x in 1: no_strata){
      model_estimate<-model_output_list[[interval*x+i-interval]][[2]][[1]]
      model_estimate$category<-rep(strata_list[x],nrow(model_estimate))
      model_estimate_all<-rbind(model_estimate_all,model_estimate)
      
      
      model_prs_reading<-data[data[,strata]==strata_list[x],
                              c(sub("_cat","",colnames(model_estimate)[1]),
                                colnames(model_estimate)[1])]
      
      model_prs_reading_decile<-data.frame(decile=NA,avg=NA)
      model_prs_reading_decile[1:length(levels(model_prs_reading[,2])),1]<-levels(model_prs_reading[,2])
      
      for (k in 1:length(levels(model_prs_reading[,2]))) {
        model_prs_reading_decile[k,2]<-mean(model_prs_reading[model_prs_reading[,2]==model_prs_reading_decile[k,1],1])
      }
      model_prs_reading_decile$category<-strata_list[x]
      model_prs_reading_decile_all<-rbind(model_prs_reading_decile_all,model_prs_reading_decile)
    }
    colnames(model_prs_reading_decile_all)[1]<-colnames(model_estimate_all)[1]
    output<-merge(model_estimate_all,model_prs_reading_decile_all,by=c(colnames(model_estimate_all)[1],"category"))
    output_all[[i]]<-output
    names(output_all)[i]<-name[i]
  }
  
  output_all
  
}




plot_FAR_strata<-function(data,model_estimate,or_hr="OR",xlab=NULL,title=NULL, case=F, 
                          estimate=F,ylab=NULL,strata,
                          colour=c("skyblue", "tomato"),
                          xlim=c(-1.8,1.8),legend=T,
                          ymin_input=NULL,ymax_input=NULL,position="right",
                          title_size=7){
  
  strata_list<-levels(data[,strata])
  no_strata<-length(strata_list)
  
  if(is.null(ymin_input)==T&is.null(ymax_input)==T){
    ymin<-min(model_estimate$LR)
    ymax<-max(model_estimate$UR)
  }else{
    ymin=ymin_input
    ymax=ymax_input
  }
  
  
  for (i in 1:no_strata){
    model_estimate$avg_new<-ifelse(model_estimate$category==strata_list[1],
                                   model_estimate$avg,
                                   model_estimate$avg+0.05*i)
  }
  
  
  
  
  
  p<- ggplot(model_estimate, aes(x=avg_new, y=estimate,colour=category,inherit.aes==T)) + 
    geom_smooth(linetype="dashed",method = "lm", se = FALSE) +
    geom_point(aes(size=0.0001/SE),shape=15,alpha=0.8)+
    geom_pointrange(aes(ymin=LR, ymax=UR),alpha=0.8,shape=15)+
    theme_classic()+
    scale_color_manual(values=colour)+
    scale_fill_discrete(name = " ")+
    scale_y_continuous(trans = "log",limits = c(ymin-0.1,ymax+0.1), breaks = seq(0.9, ymax,0.2))+
    xlab(xlab)+
    scale_x_continuous(breaks=c(model_estimate$avg),
                       labels=model_estimate[,1],limits = xlim)+
    guides(size="none")
  
  if(case==T){
    p<-p+annotate("text",x=model_estimate$avg_new, y=model_estimate$LR-0.05, 
                  label=model_estimate$case,size=3)}
  if(estimate==T){
    p<-p+annotate("text",x=model_estimate$avg_new, y=model_estimate$UR+0.05, 
                  label=model_estimate$estimate,size=3)}
  
  
  if(is.null(ylab)==T){
    p<-p+ylab(paste(or_hr, "(95%CI)"))
  }else(
    p<-p+ylab(ylab)
  )
  if(legend==T){
    p<-p+ theme(legend.position=position,
                plot.title = element_text(size = title_size, face = "bold"),
                axis.title.y = element_text(face="bold"),
                legend.title=element_blank())
  }else{
    p<-p+theme(legend.position="none",
               plot.title = element_text(size = title_size, face = "bold"),
               axis.title.y = element_text(face="bold"))
  }
  if(is.null(title)==T){
    p<-p+ggtitle(colnames(model_estimate)[1])
  }else{
    p<-p+ggtitle(title)
  }
  p
  
  
}


plot_FAR_group<-function(model_output_list,name,outcome,type="OR",data=data,
                         formal_name=NULL,xlab=NULL,
                         combine_title=NULL,graphs_path,title_size=7,
                         combine_title_size=7){
  or_hr<-ifelse(type=="OR","Odds Ratio","Hazard Ratio")
  saveor_hr<-ifelse(type=="OR","/logistic","/cox")
  no_model<-length(model_output_list)
  npgs<-length(model_output_list[[1]][[2]])
  
  library(grid)
  library(gridExtra)
  
  for(j in 1:no_model){
    png(paste(graphs_path,saveor_hr,"/FAR_ggplot_",outcome,"_",name[j],
              ".png",sep=""),width = 40,height = 30,units = "cm",res=80*7)
    ylim=data.frame(min=NA,max=NA)
    npgs=length(model_output_list[[j]][[2]])
    
    for(i in 1:npgs){
      ylim[i,1]<-min(model_output_list[[j]][[2]][[i]]$LR)
      ylim[i,2]<-max(model_output_list[[j]][[2]][[i]]$UR)
    }
    
    ymax=max(ylim$max)
    ymin=min(ylim$min)
    p<-list()
    for (i in 1:npgs){
      if(is.null(formal_name)==F){
        prs_name<-names(formal_name)[i]
        
        model_estimate<-get_FAR_input(
          model_output_list[[j]][[2]][[which(sapply(model_output_list[[j]][[2]],
                                                    function(x) colnames(x)[1] %like% paste(prs_name,"%",sep="")))]],data)
        title=formal_name[i]
        
      }else{
        model_estimate<-get_FAR_input(model_output_list[[j]][[2]][[i]],data)
        title=colnames(model_estimate)[1]
      }
      
      
      if(i==1|(i-1)%%4==0){
        p[[i]]<-plot_FAR(model_estimate=model_estimate,or_hr=type,
                         xlab=" ",title=title,ymin_input = ymin,
                         ymax_input = ymax,title_size = title_size)
        
        
      }else{
        p[[i]]<-plot_FAR(model_estimate=model_estimate,or_hr=type,
                         xlab=" ",ylab=" ",title=title,ymin_input = ymin,
                         ymax_input = ymax,title_size = title_size)
        
      }
      
      
    }
    ncol<-ifelse(npgs>4,4,npgs)
    
    grid.arrange(arrangeGrob(grobs=lapply(p, function(p) p + guides(scale="None")),
                             ncol=ncol, 
                             bottom=textGrob(xlab,gp=gpar(fontface="bold", 
                                                          col="Black", fontsize=10)),
                             top=textGrob(combine_title,
                                          gp=gpar(fontface="bold", 
                                                  col="Black", fontsize=combine_title_size)),
                             sub = textGrob("Footnote", x = 2, hjust = 1, vjust=1, 
                                            gp = gpar(fontface = "italic", 
                                                      fontsize = 10))))
    
    
    dev.off()
    
    
  }}

extract_legend <- function(my_ggp) {
  step1 <- ggplot_gtable(ggplot_build(my_ggp))
  step2 <- which(sapply(step1$grobs, function(x) x$name) == "guide-box")
  step3 <- step1$grobs[[step2]]
  return(step3)
}

plot_FAR_group_strata<-function(model_output_list,name=c("partial"),
                                outcome,type="OR",
                                data=data,strata,formal_name=NULL,
                                graphs_path,combine_title=NULL,xlab=NULL,
                                title_size=7,combine_title_size=7){
  or_hr<-ifelse(type=="OR","Odds Ratio","Hazard Ratio")
  saveor_hr<-ifelse(type=="OR","/logistic","/cox")
  strata_list<-levels(data[,strata])
  no_strata<-length(strata_list)
  no_model<-length(model_output_list)
  interval<-length(model_output_list)/no_strata #list for each strata
  npgs<-length(model_output_list[[1]][[2]])
  library(grid)
  library(gridExtra)
  
  for(j in 1:interval){
    png(paste(graphs_path,saveor_hr,"/FAR_ggplot_",outcome,"_",name[j],".png",sep=""),
        width = 40,height = 30,units = "cm",res=80*npgs)
    
    ylim=data.frame(name=NA,ymin=NA,ymax=NA,category=NA)
    for (x in 1:no_strata ){
      ylim_in<-data.frame(name=NA,ymin=NA,ymax=NA,category=rep(strata_list[x],npgs))
      for(i in 1:npgs){
        interval<-length(model_output_list)/no_strata
        ylim_in[i,2]<-min(model_output_list[[interval*x+j-interval]][[2]][[i]]$LR)
        ylim_in[i,3]<-max(model_output_list[[interval*x+j-interval]][[2]][[i]]$UR)
        ylim_in$name[i]<-colnames(model_output_list[[interval*x+j-interval]][[2]][[i]])[1]
      }
      ylim<-rbind(ylim,ylim_in)
    }
    ylim<-ylim[2:nrow(ylim),]
    
    ymax=max(ylim$ymax)
    ymin=min(ylim$ymin)
    
    p_output<-list()
    for (i in 1:npgs){
      
      model_in<-list()
      
      
      for(x in 1:no_strata){
        
        if(is.null(formal_name)==F){
          prs_name<-formal_name[i]
        }else{
          prs_name<-rownames(model_output_list[[interval*x+j-interval]][[1]])[i]
        }
        prs_ncol<-which(sapply(model_output_list[[interval*x+j-interval]][[2]], 
                               function(x) colnames(x)[1]%like% paste(names(prs_name),"%",sep="")))
        model_prs_input<-list(model_output_list[[interval*x+j-interval]][[1]][prs_ncol,],
                              list(model_output_list[[interval*x+j-interval]][[2]][[prs_ncol]]))
        
        model_in[[x]]<- model_prs_input
        
      }
      input<-get_FAR_input_strata(model_output_list = model_in,
                                  strata =strata,data ,name)
      
      title=prs_name
      
      
      if(i==1|(i-1)%%4==0){
        p<-plot_FAR_strata(input[[1]],case=F,estimate=F,xlab=" ",strata=strata,title=title,legend=F,
                           ymin_input = ymin,ymax_input = ymax,title_size=title_size)
        
        
        
        
        p_output[[i]]<-p
        q<-plot_FAR_strata(input[[1]],case=F,estimate=F,xlab=" ",strata=strata,
                           title=title,legend=T,position = "bottom",title_size=title_size)
        
        shared_legend <- extract_legend(q)
        
      }else{
        p<- plot_FAR_strata(input[[1]],case=F,estimate=F,xlab=" ",strata=strata,
                            title=title,ylab=" ",legend = F,
                            ymin_input = ymin,ymax_input = ymax)
        
        p_output[[i]]<-p  }
      
    }
    
    
    
    ncol<-ifelse(npgs>4,4,npgs)
    
    grid.arrange(arrangeGrob(grobs=lapply(p_output, function(p) p + guides(scale="None")),
                             ncol=ncol, 
                             bottom=textGrob(xlab,gp=gpar(fontface="bold", 
                                                          col="Black", fontsize=10)),
                             top=textGrob(combine_title,
                                          gp=gpar(fontface="bold", 
                                                  col="Black", fontsize=combine_title_size)),
                             sub = textGrob("Footnote", x = 2, hjust = 1, vjust=1, 
                                            gp = gpar(fontface = "italic", 
                                                      fontsize = 10))),
                 shared_legend ,heights=c(5, 0.5),nrow=2)
    
    
    
    
    
    
    dev.off()
    
    
    
  }
}


# comparison plots (two forests)---------------------------------------------------

#option 1 (layover)
forest_comparison_table<-function(data,strata_in,adjustment_list,prs,outcome,model_name,or_hr="OR"){
  strata_level<-levels(data[,strata_in])
  n_model=length(adjustment_list)
  model_output_list<-list()
  for(i in 1:n_model){
    all_strata_outcome<-run_stratified(data, strata_in = confounder_check,
                                       outcome=outcome,adjustment = adjustment[[i]],
                                       se=F,show_int = F,prs=prs)
    model_output_list[[i]]<-all_strata_outcome[[1]]
    names(model_output_list)[i]<-model_name[i]
  }
  
  for(i in 1:length(strata_level)){
    strata<-strata_level[i]
    model_in_list<-list()
    for (j in 1:n_model){
      model_in_list[[j]]<-model_output_list[[j]][[which(names(model_output_list[[j]])==strata)]]
    }
    
    forest_table<-generate_forest_table(
      tables=model_in_list,
      model_name = model_name,or_hr = "OR",show_prsname = F)
    
    colnames(forest_table)[4:6]<-paste(colnames(forest_table)[4:6],"_",strata,sep="")
    colnames(forest_table)[7]<-paste(or_hr," per SD (95%CI)")
    forest_table$"Case/control"<-paste(forest_table$`Number of cases`,"/",forest_table$`Number of controls`,sep="")
    forest_table$"Case/control"[seq(1,nrow(forest_table),by=(n_model+1))]<-""
    
    
    if(i==1){
      model_to_combine<-forest_table[,c(1,11,4:8,10)]
      
    }else{
      colnames(forest_table)[c(2,3,7:11)]<-paste(colnames(forest_table)[c(2,3,7:11)]," ",sep="")
      model_to_combine<-cbind(model_to_combine,forest_table[,c(11,4:8,10)])
    }
    
    
  }
  model_to_combine
}


setup_theme_comparison<-function(fontsize=10,font="",
                                 summary_fill="white",
                                 title_cex=1,background_col="white",
                                 ci_col=c("black","pink"),ci_fill=c("black","pink"),
                                 refline_col="black",
                                 ci_pch=c(15,16),ci_alpha=1,legend_name=c("Gender"), 
                                 legend_value = c("Men", "Women")){
  
  suppressWarnings( 
    tm <- forest_theme(base_size = fontsize,
                       core = list(bg_params=list(fill = c(background_col))),
                       colhead=list(fg_params=list(hjust=0.5, x=0.5)),
                       summary_col = "black",
                       summary_fill=summary_fill,
                       refline_lty = "solid",
                       ci_pch = ci_pch,
                       ci_col =ci_col,
                       ci_fill=ci_fill,
                       footnote_col = "black",
                       footnote_cex = 0.9,
                       vertline_lwd = 1,
                       vertline_lty = "dashed",
                       vertline_col = "grey20",
                       xaxis_cex=0.9,
                       ci_lty =1 ,
                       ci_lwd = 1,
                       ci_Theight = 0.2,
                       title_cex =title_cex,
                       ref_lty="solid",
                       refline_col = refline_col,
                       base_family = font ,
                       title_fontfamily = font,
                       ci_alpha=ci_alpha,
                       legend_name = legend_name,
                       legend_value=legend_value))
  tm
}



plot_comparison<-function(forest_table,col_input=c(1,2,6,7,9,13,14,15,16),
                          est=c("estimate"),
                          lower=c("LR"),upper=c("UR"),ci_column=8,
                          footnote="",fontsize=10,font="",
                          summary_fill="white",
                          title_cex=1,background_col="white",
                          ci_col=c("black","pink"),ci_fill=c("black","pink"),
                          refline_col="black",
                          ci_pch=c(15,16),ci_alpha=1,legend_name=c("Gender"), 
                          legend_value = c("Men", "Women")){
  
  tm<-setup_theme_comparison(fontsize=fontsize,font=font,
                             summary_fill=summary_fill,
                             title_cex=title_cex,background_col=background_col,
                             ci_col=ci_col,ci_fill=ci_fill,
                             refline_col=refline_col,
                             ci_pch=ci_pch,ci_alpha=ci_alpha,
                             legend_name=legend_name, 
                             legend_value = legend_value)
  
  
  
  est=colnames(forest_table)[which(colnames(forest_table) %flike% est)]
  lower=colnames(forest_table)[which(colnames(forest_table) %flike% lower)]
  upper=colnames(forest_table)[which(colnames(forest_table) %flike% upper)]
  
  est_in<-list()
  lower_in<-list()
  upper_in<-list()
  for(i in 1:length(est)){
    est_in[[i]]<-as.numeric(forest_table[,est[i]])
    lower_in[[i]]<-as.numeric(forest_table[,lower[i]])
    upper_in[[i]]<-as.numeric(forest_table[,upper[i]])
  }
  
  
  
  
  p <- forest(forest_table[,col_input],
              est = est_in,
              lower = lower_in, 
              upper = upper_in,
              ci_column = ci_column,
              ref_line = 1,
              arrow_lab =c("Lower risk of CAD", "Higher risk of CAD") ,
              xlim = c(0.9,1.45),
              ticks_at = c(0.9,1,1.1,1.2,1.3,1.4),
              footnote = paste("\n\n\n\n\n\n\n\n\n ",footnote,sep=""),
              theme = tm)
  
  
  
  for (i in 1: length(est)){
    p <- add_text(p, text = legend_value[i],
                  part = "header", 
                  col = c((3*i-1):(3*i+1)),row=0,
                  gp = gpar(fontface="bold",fontsize=8))
    if(i<length(est)){
      p <- add_border(p, where=c("left"),
                      part = "body", 
                      col = c((3*i+1)),row=1:nrow(forest_table),
                      gp = gpar(lwd = .5))}
  }
  
  
  p <- add_text(p, text = c("OR comparison between gender"),
                part = "header", 
                col = ci_column,row=1,
                gp = gpar(fontface="bold",fontsize=fontsize))
  
  
  
  p <- add_border(p, 
                  part = "header", 
                  row = 1,
                  col = 1:length(col_input), gp = gpar(lwd = 1))
  
  
  p <- add_border(p, 
                  part = "body", 
                  col = c(2:(3*length(est)+1)),row=1:nrow(forest_table),
                  gp = gpar(lwd = .5))
  
  
  row_in<-which(sapply(forest_table[,1],function(x) grepl("\U{00A0}\U{00A0}\U{00A0}\U{00A0}",x))+
                  sapply(forest_table[,1],function(x) grepl("\U{00A0}\U{00A0}",x))==0)
  p<- edit_plot(p, row=row_in, col=1,
                gp = gpar(fontface = "bold"))
  
  
  
  
}



discrimination_without_prs<-function(train_data,test_data,partial_adjustments,full_adjustments,outcome){
  #partial#
  train_partial<-na.omit(train_data%>%select(IID,partial_adjustments,contains(c("PGS","custom",outcome))))
  test_partial<-na.omit(test_data%>%select(IID,partial_adjustments,contains(c("PC","PGS","custom",outcome))))
  model_partial<-run_glm(data=train_partial,partial_adjustments,outcome,prs_name=NULL)
  #full#
  train_full<-na.omit(train_data%>%select(IID,full_adjustments,contains(c("PGS","custom",outcome))))
  test_full<-na.omit(train_data%>%select(IID,full_adjustments,contains(c("PGS","custom",outcome))))
  model_full<-run_glm(data=train_full,full_adjustments,outcome,prs_name=NULL)
  
  pred<-predict(model_partial,test_partial,type='response')
  roc_prs<-roc(test_partial[,outcome],pred)
  auc_point<-auc(roc_prs)
  auc_ci<-ci.auc(test_partial[,outcome],pred)
  model_output<-data.frame(AUC=NA,AUC_LR=NA,AUC_UR=NA,pseudoR=NA)
  model_output[1,]<-c(auc_point,auc_ci[1],auc_ci[3],PseudoR2(model_partial))
  rownames(model_output)[1]<-"partial"
  
  pred<-predict(model_full,test_full,type='response')
  roc_prs<-roc(test_full[,outcome],pred)
  auc_point<-auc(roc_prs)
  auc_ci<-ci.auc(test_full[,outcome],pred)
  model_output[2,]<-c(auc_point,auc_ci[1],auc_ci[3],PseudoR2(model_full))
  rownames(model_output)[2]<-"full"
  model_output
  model_output[,5]<-paste(round(model_output[,1],3),"(",round(model_output[,2],3),"-",round(model_output[,3],3),")",sep="")
  colnames(model_output)[5]<-"AUC(95%CI)"
  model_output
}

