Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)
library(zoo)
setwd("/Users/subramanya/Dropbox/Project/Code/ElasticSim/r_scripts");
source("config.r");
workload=read.csv(WORKLOAD,sep=",",header=F);
workload_header=c("UnixTimeStamp","ActiveSessions");
colnames(workload) <- workload_header;
workloadsize=length(workload$ActiveSessions);
trainsamples=workloadsize/2;
testsamples=workloadsize/2;
workload$posxtime=as.POSIXct(workload$UnixTimeStamp, origin="1970-01-01"); 
workload_tsdata=zoo(workload$ActiveSessions,workload$posxtime);

#predict for scaleup
arimaScaleupPrediction=c();
for (i in seq(trainsamples,workloadsize,LOOKAHEAD_SCALEUP)){
  arimaFit=auto.arima(workload_tsdata[1:i])
  pred=forecast(arimaFit,h=LOOKAHEAD_SCALEUP)
  sink("accuracy_scaleup.log",append =T);
  print(accuracy(pred));
  sink();
  arimaScaleupPrediction=c(arimaScaleupPrediction,pred$mean);
}
predicted_scaleup=zoo(arimaScaleupPrediction[1:testsamples],workload$posxtime[trainsamples+1:workloadsize]);
forecastedscaleup=data.frame(workload$UnixTimeStamp[2501:5000],arimaScaleupPrediction[1:2500])
write.csv(forecastedscaleup,FORECAST_SCALEUP_WORKLOAD,row.names=FALSE,col.names=FALSE);

#predict for scaledown
arimaScaledownPrediction=c();
for (i in seq(trainsamples,workloadsize,LOOKAHEAD_SCALEDOWN)){
  arimaFit=auto.arima(workload_tsdata[1:i])
  pred=forecast(arimaFit,h=LOOKAHEAD_SCALEDOWN)
  sink("accuracy_scaledown.log",append =T);
  print(accuracy(pred));
  sink();
  arimaScaledownPrediction=c(arimaScaledownPrediction,pred$mean);
}
predicted_scaledown=zoo(arimaScaledownPrediction[1:testsamples],workload$posxtime[trainsamples+1:workloadsize]);
forecastedscaledown=data.frame(workload$UnixTimeStamp[2501:5000],arimaScaleupPrediction[1:2500])
write.csv(forecastedscaledown,FORECAST_SCALEDOWN_WORKLOAD,row.names=FALSE,col.names=FALSE)

