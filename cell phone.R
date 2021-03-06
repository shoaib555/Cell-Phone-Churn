#Reading the data set into R and exploring the structure and the variables, 
#The values for the numeric variables appear to be normally except for the variable
#CustomerServCall(Skewed to the right) and Data Usage distributed, and some varibale 
#need to be converted to factor variable for the ease of analysis.
rm(list=ls())
library(readxl)
library(DataExplorer)
ce=read_excel("cell.xlsx",sheet = "Data")
str(ce)
dim(ce)
plot_histogram(ce)

#Formating the data, checking for Missing Values and converting the variables 
#Churn,DataPlan,Contract Renewal into factor variables for the ease of analysis,
#the variable CustomerServCalls has values in decimals, rounding it to make more sense 
#by creating a new variable CustServCalls1 and also converting the variable AccountWeeks to 
#a new variable Lifeterm to determine how many years a particular customer has used the
#service(rounding it to 0 if customer has not completed a year since contract).
#The  maximum LifeTerm of a customer is 5 and there inj only one customer who has
#completed 5 years(Deleting that observation and converting LifeTerm to a factor variable with 5 levels),
#the DataUsage of the customers seem to be to be very low may be a potential reason for Customer Churn.

library(DataExplorer)
plot_missing(ce)
ce$Churn=as.factor(ce$Churn)
ce$ContractRenewal=as.factor(ce$ContractRenewal)
ce$DataPlan=as.factor(ce$DataPlan)
ce$Accountweeks1=round((ce$AccountWeeks/52.14),0)
summary(ce$Accountweeks1)
ce$CustServCalls1=round(ce$CustServCalls,0)
summary(ce$CustServCalls)
summary(ce)
ce$Accountweeks1=as.numeric(ce$Accountweeks1)
which(ce$Accountweeks1==5)
ce=ce[-818,]
ce$Accountweeks1=as.factor(ce$Accountweeks1)
summary(ce$Accountweeks1)
colnames(ce)[12]="LifeTerm"
ce=ce[,-c(2,6)]
summary(ce$DataUsage)
str(ce)

#Visualizing the factor and Numeric variables against the DV Churn, Churn happens
#for those who have used the service for 1 to 3 years, 10% Customer who renwed their
#contract recently have churned to the overall 14.45%, 12% of customers who do not have
#a DataPlan have churned,as compared to those who have a DataPlan which is 2% and 7% who have used the service for 2 years.

cef=ce[,c(2,3,10)]
par(mfrow=c(2,2))
for (i in names(cef)) {
  print(i)
  print(table(ce$Churn, cef[[i]]))
  barplot(table(ce$Churn, cef[[i]]),
          col=c("grey","red"),
          main = names(cef[i]))
  
  
  
}


aggregate(ce$DayMins,by=list(ce$Churn),mean)
aggregate(ce$MonthlyCharge,by=list(ce$Churn),mean)
aggregate(ce$DataUsage,by=list(ce$Churn),mean)
aggregate(ce$DayCalls,by=list(ce$Churn),mean)
aggregate(ce$CustServCalls1,by=list(ce$Churn),mean)
aggregate(ce$OverageFee,by=list(ce$Churn),mean)
table(ce$Churn,ce$ContractRenewal,ce$LifeTerm)
library(dplyr)
ce%>%filter(DayMins>175)%>%group_by(Churn)%>%summarize(count=n())

#The interquartile range of DataUsage for the Churned customers is 
#narrow or close to zero and is skewed to the right and customers with 
#lowest DataUsage have churned,DayMins has a higher IQR for churned customer 
#as to non churned customer and DayMins for churned is skewed to the left also 
#highest number of call made are by the customers who have churned,MonthlyCharge 
#for churned customers is skewed to the left and Monthlr charge is as wll highest for 
#churned customers,number of calls made to customer sevice is aswell for the churned customers.

ce1=ce[,c(4:9,11)]
ce2 <- cbind(ce1, ce$Churn)
colnames(ce2)[8] <- "Churn"
ce2$Churn=as.factor(ce2$Churn)
str(ce2)
library(reshape2)
library(ggplot2)
nd2.melt<- melt(ce2, id = c("Churn"))
library(tidyverse)
zz <- ggplot(nd2.melt, aes(x=Churn, y=value))
zz+geom_boxplot(aes(color=Churn), alpha=0.7 ) +
  facet_wrap(~variable,scales = "free_x", nrow = 3)+
  coord_flip()+ggtitle("Boxplots for all continous variable vs churn")

#Using Churn as target variable and plotting a scatter plot 
#against the predictor variables MonthlyCharge on the x-axis
#and OverageFees on the y-axis and splitting it across factors LifeTerm and Contract Renewal.
bk=ggplot(ce,aes(x=OverageFee,y=MonthlyCharge,color=Churn))
bk+geom_point(aes(color=Churn))+facet_grid(ContractRenewal~LifeTerm)+ggtitle("overagefee vs monthly charge against contract renewal and life term")

#Observation: As observed earlier churn occurs mostly 
#in between the 1st and 3rd year LifeTerm of a customer.
#The customer with high MontlyCharges regardless of the contract being 
#renewed or not have churned.MontlyCharges could be another potential reason for Churn.


#Using Churn as target variable and plotting a scatter
#plot against the predictor variables MonthlyCharge on the 
#x-axis and OverageFees on the y-axis and splitting it across 
#factors DataPlan(2 levels)and Contract Renewal(2 levels).

bk=ggplot(ce,aes(x=OverageFee,y=MonthlyCharge,color=Churn))
bk+geom_point(aes(color=Churn))+facet_grid(ContractRenewal~DataPlan)+ggtitle("overagefee vs monthly against contract renewal and data plan")
table(ce$Churn,ce$ContractRenewal,ce$DataPlan)

#Observation:Customers with Active DataPlan and who have recently 
#renewed the contract have churned at 1.3% as compared to those customer 
#who don't have an active DataPlan but have renewed their contract recently which is 9%.


#Checking for Multicollinearity between numeric variables by using
#corrplot and running a simple liner regression Model by taking MonthlyCharges as DV.

library(corrplot)
corrplot(cor(ce[,-c(1,2,3,10)]),method = "number")
library(car)
m=lm(MonthlyCharge~Churn+LifeTerm+ContractRenewal+DataPlan+CustServCalls1+DayMins+DayCalls+OverageFee+RoamMins,data=ce)
summary(m)
vif(m)
corrplot(cor(ce[,-c(1,2,3,4,10)]),method = "number",type="upper")

#Running Chi-square test on the factor variables to check for significance against the DV Churn, 
cef1=cbind(cef,ce$Churn)
str(cef1)
colnames(cef1)[4]="Churn"
cef1
ChiSqStat <- NA
for ( i in 1 :(ncol(cef1))){
  Statistic <- data.frame(
    "Row" = colnames(cef1[4]),
    "Column" = colnames(cef1[i]),
    "Chi SQuare" = chisq.test(cef1[[4]], cef1[[i]])$statistic,
    "df"= chisq.test(cef1[[4]], cef1[[i]])$parameter,
    "p.value" = chisq.test(cef1[[4]], cef1[[i]])$p.value)
  ChiSqStat <- rbind(ChiSqStat, Statistic)
}
ChiSqStat <- data.table::data.table(ChiSqStat)
ChiSqStat

ce=ce[,-10]

#Logistic Regression
#Running a univariate logistic regresssion model to check for significance of a variable,
#Daycalls appears to be insignificant based on the p-value.
mod.num <- glm(Churn~DataUsage, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~DayMins, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~DayCalls, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~MonthlyCharge, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~OverageFee, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~RoamMins, data = ce, family = binomial)
summary(mod.num)

mod.num <- glm(Churn~CustServCalls1, data = ce, family = binomial)
summary(mod.num)

set.seed(1231)
library(caTools)
str(ce)
ce=as.data.frame(ce)
spl = sample.split(ce$Churn, SplitRatio=0.65)
train = subset(ce, spl ==T)
test = subset(ce, spl==F)
dim(train)
dim(test)
## Check split consistency to see there are comparable % number of response variables
#with similar responses between train, test and the full data
#Redo the sampling if the % is way off
sum(as.integer(as.character(train$Churn))) / nrow(train)
sum(as.integer(as.character(test$Churn))) / nrow(test)
sum(as.integer(as.character(ce$Churn))) / nrow(ce)

m2 = glm(Churn~DataPlan+CustServCalls1+DayMins+OverageFee+RoamMins, data = train, family= binomial)
summary(m2)

#Check for multi collinearity using vif function. Same as in linear regression
library(car)  
vif(m2)



#Validating the model on both train and test.

#Predict the response using the model on the train data
predTrain = predict(m2, newdata= train, type="response")
#Assume >0.5 as true and other way as False, build a confusion matrix
conf_mat1 <- table(train$Churn, predTrain >0.5)
conf_mat1
#Get the accuracy by using the right classifiers
(conf_mat1[1,1]+conf_mat1[2,2])/nrow(train)
(conf_mat1[1,2]+conf_mat1[2,1])/nrow(train)


#Plot the ROC curve for calculating AUC
library(ROCR)
ROCRpred = prediction(predTrain, train$Churn)
as.numeric(performance(ROCRpred, "auc")@y.values)
perf = performance(ROCRpred, "tpr","fpr")
plot(perf,col="black",lty=2, lwd=2)
plot(perf,lwd=3,colorize = TRUE)

#Kolgomorov-Smirnov
ks_tr=max(perf@y.values[[1]]-perf@x.values[[1]])
plot(perf,main=paste0("KS=",round(ks_tr*100,5),"%"))

library(lift)
plotLift(tr$prob,tr$PL,cumulative = T)
plotLift(te$prob,te$PL,cumulative = T)

#Predict the response using the model on the test data
predTest = predict(m2, newdata= test, type="response")

#Assume >0.5 as true and other way as False, build a confusion matrix
conf_mat <- table(test$Churn, predTest>0.5)
conf_mat
#Get the accuracy by using the right classifiers
(conf_mat[1,1]+conf_mat[2,2])/nrow(test)
(conf_mat[2,1]+conf_mat[1,2])/nrow(test)



#Plot the ROC curve for calculating AUC
library(ROCR)
ROCRpred1 = prediction(predTest, test$Churn)
as.numeric(performance(ROCRpred1, "auc")@y.values)
perf1 = performance(ROCRpred1, "tpr","fpr")
plot(perf1,col="black",lty=2, lwd=2)
plot(perf1,lwd=3,colorize = TRUE)

#Kolgomorov-Smirnov
ks_tr=max(perf1@y.values[[1]]-perf1@x.values[[1]])
plot(perf1,main=paste0("KS=",round(ks_tr*100,5),"%"))

train$prob=predict(m2,data=train,type="response")
test$prob=predict(m2,test,type="response")
library(ineq)
ineq(train$prob,"gini")
ineq(test$prob,"gini")


library(lift)
plotLift(train$prob,train$Churn,cumulative = T)
plotLift(test$prob,test$Churn,cumulative = T)

final= glm(Churn~DataPlan+CustServCalls1+DayMins+OverageFee+RoamMins, data = train, family= binomial)
summary(final)



library(blorr)
blr_step_aic_both(final, details = FALSE)

#Plot the gains chart
k <- blr_gains_table(final)
plot(k)

#Kolgomorov-Smirnov
blr_ks_chart(k, title = "KS Chart",
             yaxis_title = " ",xaxis_title = "Cumulative Population %",
             ks_line_color = "black")
#Kolgomorov-Smirnov
blr_ks_chart(k, title = "KS Chart",
             yaxis_title = " ",xaxis_title = "Cumulative Population %",
             ks_line_color = "black")


#Lift Chart
blr_decile_lift_chart(k, xaxis_title = "Decile",
                      yaxis_title = "Decile Mean / Global Mean",
                      title = "Decile Lift Chart",
                      bar_color = "blue", text_size = 3.5,
                      text_vjust = -0.3)

#KNN

ce=read_excel("cell.xlsx",sheet = "Data")
str(ce)
ces=ce
normalize<-function(x){
  +return((x-min(x))/(max(x)-min(x)))}
ces$AccountWeeks1=normalize(ces$AccountWeeks)
ces$ContractRenewal1=normalize(ces$ContractRenewal)
ces$DataPlan1=normalize(ces$DataPlan)
ces$DataUsage1=normalize(ces$DataUsage)
ces$CustServCalls1=normalize(ces$CustServCalls)
ces$DayMins1=normalize(ces$DayMins)
ces$DayCalls1=normalize(ces$DayCalls)
ces$MonthlyCharge1=normalize(ces$MonthlyCharge)
ces$OverageFee1=normalize(ces$OverageFee)
ces$RoamMins1=normalize(ces$RoamMins)
ces1=ces[,c(1,12:21)]
ces1=as.data.frame(ces1)

set.seed(1234)
library(caTools)
sample=sample.split(ces1,SplitRatio = 0.7)
tr=subset(ces1,sample==T)
te=subset(ces1,sample==F)
head(tr)

library(class)
y.pred3=knn(train=tr[,-1],test=te[-1],cl=tr[,1],k=3)
tab.knn.3=table(te[,1],y.pred3)
tab.knn.3
acc=sum(diag(tab.knn.3))/sum(tab.knn.3)
acc
loss=tab.knn.3[2,1]/(tab.knn.3[2,1]+tab.knn.3[1,1])
loss



y.pred5=knn(train=tr[,-1],test=te[-1],cl=tr[,1],k=5)
tab.knn.5=table(te[,1],y.pred5)
tab.knn.5
acc=sum(diag(tab.knn.5))/sum(tab.knn.5)
acc
loss=tab.knn.5[2,1]/(tab.knn.5[2,1]+tab.knn.5[1,1])
loss


y.pred9=knn(train=tr[,-1],test=te[-1],cl=tr[,1],k=11)
tab.knn.9=table(te[,1],y.pred5)
tab.knn.9
acc=sum(diag(tab.knn.9))/sum(tab.knn.9)
acc
loss=tab.knn.9[2,1]/(tab.knn.9[2,1]+tab.knn.9[1,1])
loss

#Naive Bayes
ce=read_excel("cell.xlsx",sheet = "Data")
ce$Churn=as.factor(ce$Churn)
ce$ContractRenewal=as.factor(ce$ContractRenewal)
ce$DataPlan=as.factor(ce$DataPlan)
ce$Accountweeks1=round((ce$AccountWeeks/52.14),0)
summary(ce$Accountweeks1)
ce$CustServCalls1=round(ce$CustServCalls,0)
summary(ce$CustServCalls)
summary(ce)
ce$Accountweeks1=as.numeric(ce$Accountweeks1)
which(ce$Accountweeks1==5)
ce=ce[-818,]
ce$Accountweeks1=as.factor(ce$Accountweeks1)
summary(ce$Accountweeks1)
colnames(ce)[12]="LifeTerm"
ce=ce[,-c(2,6)]
summary(ce$LifeTerm)
summary(ce$CustServCalls1)
ce$CustServCalls1=as.factor(ce$CustServCalls1)
summary(ce$CustServCalls1)
str(ce)
summary(ce$RoamMins)
ce$Roam=as.numeric(cut(ce$RoamMins,4))
str(ce)
ce$Roam=as.factor(ce$Roam)
str(ce$Roam)
summary(ce$CustServCalls1)
ce$CustServCalls1=as.numeric(ce$CustServCalls1)
ce$CustServ=as.numeric(cut(ce$CustServCalls1,4))
summary(ce$CustServ)
ce$CustServ=as.factor(ce$CustServ)
summary(ce$CustServ)
summary(ce$OverageFee)
ce$Fee=as.numeric(cut(ce$OverageFee,4))
ce$Fee=as.factor(ce$Fee)
summary(ce$Fee)
summary(ce$OverageFee)
ce$Fee=as.numeric(cut(ce$OverageFee,4))
ce$Fee=as.factor(ce$Fee)
summary(ce$Fee)
summary(ce$DataUsage)
ce$Data=as.numeric(cut(ce$DataUsage,2))
ce$Data=as.factor(ce$Data)
summary(ce$Data)
summary(ce$DayMins)
ce$Day=as.numeric(cut(ce$DayMins,5))
ce$Day=as.factor(ce$Day)
summary(ce$Day)
summary(ce$DayCalls)
ce$Calls=as.numeric(cut(ce$DayCalls,3))
ce$Calls=as.factor(ce$Calls)
summary(ce$Calls)
summary(ce$MonthlyCharge)
ce$Charge=as.numeric(cut(ce$MonthlyCharge,4))
ce$Charge=as.factor(ce$Charge)
summary(ce$Charge)
ce=ce[,c(1:3,10:18)]
ce=ce[,-5]
str(ce)
ce=as.data.frame(ce)


library(caTools)
set.seed(100)
spl=sample.split(ce,SplitRatio = 0.7)
trn=subset(ce,spl==T)
tes=subset(ce,spl==F)
dim(trn)
dim(tes)

library(e1071)
NB=naiveBayes(x=trn[,-1],y=trn$Churn)
y_pred=predict(NB,newdata=trn[-1])

#confusion matrix
tab.nb=table(trn$Churn,y_pred)
tab.nb
acc=sum(diag(tab.nb))/sum(tab.nb)
acc
(tab.nb[2,1]+tab.nb[1,2])/nrow(trn)



y_pred1=predict(NB,newdata=tes[-1])

tab.nb=table(tes$Churn,y_pred1)
tab.nb
acc=sum(diag(tab.nb))/sum(tab.nb)
acc
(tab.nb[2,1]+tab.nb[1,2])/nrow(trn)