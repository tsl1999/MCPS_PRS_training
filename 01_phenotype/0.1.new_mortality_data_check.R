phenotype_path<-"/well/emberson/projects/mcps/data/phenotypes/"
data<-data.frame(fread(paste("/well/emberson/users/hma817/projects/MCPS_PRS_training/data", '/extracted-phenotypes.txt',sep=''), header=T,dec =".",fill=T))
data<-data[is.na(data$IID)!=T&is.na(data$PC1)!=T&is.na(data$SEX)!=T&is.na(data$AGE)!=T,]
Mortality1<-data.frame(fread(paste(phenotype_path,"v3.1_DEATHS.csv",sep = "")))
Mortality2<-data.frame(fread(paste(phenotype_path,"v2.1_DEATHS.csv",sep = "")))

nrow(Mortality2)#30635
nrow(Mortality1)#34079
sum(Mortality2$REGISTRO%in%Mortality1$registro)#30049
sum(!Mortality2$REGISTRO%in%Mortality1$registro)#586 deaths in 2.1 did not show up in 3.1
mort2_grade_overc_id<-Mortality2[Mortality2$grade%in%c("D","E","F","U","Z"),"REGISTRO"]#2515
mort2_grade_belowc_id<-Mortality2[!Mortality2$grade%in%c("D","E","F","U","Z"),"REGISTRO"]#28120
mort1_grade_overc_id<-Mortality1[Mortality1$grade%in%c("D","E","F","U","Z"),"registro"]#3108
mort1_grade_belowc_id<-Mortality1[!Mortality1$grade%in%c("D","E","F","U","Z"),"registro"]#30971

sum(mort2_grade_overc_id%in%mort1_grade_overc_id)#2297
sum(!mort2_grade_overc_id%in%mort1_grade_overc_id)#218 unverified in 2.1 not appeared in 3.1 unverified 

sum(mort2_grade_belowc_id%in%mort1_grade_overc_id)#159 verified in 2.1 became unverified


#3000ish more deaths
#500 more unverified deaths-- needs removal of participants




process_mortality<-function(Mortality,date){
  colnames(Mortality)[1]<-"REGISTRO"
  mortality<-Mortality[!Mortality$grade%in%c("D","E","F","U","Z"),]
  mortality_remove<-Mortality[Mortality$grade%in%c("D","E","F","U","Z"),]
  table(mortality$grade,exclude=NULL)
  table(mortality_remove$grade)
  reg_link<-data.frame(fread(paste(phenotype_path,"RGN_LINK_IID.csv",sep = "")))
  mortality_birth<-merge(mortality[,c(1,3,4,13)],reg_link[,c(1,3)], by="REGISTRO")
  mortality_remove<-left_join(mortality_remove[,c(1,4,13)],reg_link[,c(1,3)], by="REGISTRO")
  
  data<-left_join(data,mortality_birth[,c(1:5)],by="IID")
  data_remove<-data[data$IID%in%mortality_remove$IID,]
  data<-data[!data$IID%in%mortality_remove$IID,]
  
  
  data$AGE_80<-ifelse(data$AGE>=80,NA,data$AGE)
  data$AGE_80_over<-ifelse(data$AGE>=80,data$AGE,NA)
  sum(is.na(data$AGE_80)==F)
  data$DATE_RECRUITED<-as.Date(data$DATE_RECRUITED,"%d%b%Y")
  data$DATE_OF_DEATH<-as.Date(data$DATE_OF_DEATH,"%d/%m/%Y")
  
  data$date_since_recruitment<-as.Date(date,"%Y-%m-%d")-data$DATE_RECRUITED
  data$yr_since_recruitment<-as.numeric(data$date_since_recruitment)/365.25
  data$yrs_died_recruitment<-(data$DATE_OF_DEATH-data$DATE_RECRUITED)/365.25
  
  data$AGE_followup<-ifelse(is.na(data$yrs_died_recruitment)==F,round(data$AGE+data$yrs_died_recruitment,4),ifelse(
    is.na(data$yrs_died_recruitment)==T, round(data$AGE+data$yr_since_recruitment,4),NA
  ))
  
  
  #remove baseline age over 80, recode death after 80 as control, combine baseline and CAD mortality------------------
  data_keep<-data[is.na(data$AGE_80)==F,]
  data_keep$EPA001_up<-ifelse(data_keep$EPA001==1&data_keep$AGE_followup<=80,1,0)
  data_keep$EPO001_up<-ifelse(data_keep$EPO001==1&data_keep$AGE_followup<=80,1,0)
  
  data_keep$prevalent_CHD_EPA<-ifelse(data_keep$BASE_CHD==1,1,ifelse(is.na(data_keep$EPA001_up)==F&data_keep$EPA001_up==1,1,0))
  data_keep$prevalent_CHD_EPA<-factor(data_keep$prevalent_CHD_EPA,levels=c(0,1))
  data_keep$prevalent_CHD_EPO<-ifelse(data_keep$BASE_CHD==1,1,ifelse(is.na(data_keep$EPO001_up)==F&data_keep$EPO001_up==1,1,0))
  data_keep$prevalent_CHD_EPO<-factor(data_keep$prevalent_CHD_EPO,levels=c(0,1))
  print(table(data_keep$prevalent_CHD_EPA))
  data_keep
  }

mort1_datakeep<-process_mortality(Mortality = Mortality1,date="2022-08-31")
mort2_datakeep<-process_mortality(Mortality = Mortality2,date="2020-12-31")


nrow(mort1_datakeep)
nrow(mort2_datakeep)
sum(mort1_datakeep$IID%in%mort2_datakeep$IID)




a<-mort2_datakeep[mort2_datakeep$prevalent_CHD_EPA==1,"IID"]
areg<-mort2_datakeep[mort2_datakeep$prevalent_CHD_EPA==1,"REGISTRO"]
b<-mort1_datakeep[mort1_datakeep$prevalent_CHD_EPA==1,"IID"]
breg<-mort1_datakeep[mort1_datakeep$prevalent_CHD_EPA==1,"REGISTRO"]

sum(a%in%b)#4871
not_in_3<-a[!a%in%b]#41 cases that were CAD death in v2.1 were reclassified as alive or control
#not_in_3_reg<-areg[!areg%in%breg]

check<-mort2_datakeep[mort2_datakeep$IID%in%not_in_3,]
check2<-mort1_datakeep[mort1_datakeep$IID%in%not_in_3,]

not_in_2<-b[!b%in%a]#26 new cases classified as CAD death
check<-mort2_datakeep[mort2_datakeep$IID%in%not_in_2,]
check2<-mort1_datakeep[mort1_datakeep$IID%in%not_in_2,]
