Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)
library(zoo)
setwd("/Users/subramanya/Dropbox/Project/Code/ElasticSim/r_scripts");
source("config.r");

scaleup_forecast_header = c("UnixTimeStamp","ScaleupForecast");
scale_up_workload = read.csv(FORECAST_SCALEUP_WORKLOAD,sep=",",header=F);
colnames(scale_up_workload)  <- scaleup_forecast_header; 

scaledown_forecast_header = c("UnixTimeStamp","ScaledownForecast");
scale_down_workload = read.csv(FORECAST_SCALEDOWN_WORKLOAD,sep=",",header=F);
colnames(scale_down_workload)  <- scaledown_forecast_header; 

actual_header = c("UnixTimeStamp","ActualWorkload");
actual_workload = read.csv(ACTUAL_WORKLOAD,sep=",",header=F);
colnames(actual_workload)  <- actual_header; 

scale_up_workload$PosxTime= as.POSIXct(scale_up_workload$UnixTimeStamp, origin="1970-01-01");
tsdata.forecast_scaleup = zoo(scale_up_workload$ScaleupForecast,scale_up_workload$PosxTime);
tsdata.forecast_scaledown = zoo(scale_down_workload$ScaledownForecast,scale_up_workload$PosxTime);
tsdata.actual = zoo(actual_workload$ActualWorkload,scale_up_workload$PosxTime);
tsdata.together = merge(tsdata.actual,tsdata.forecast_scaleup,tsdata.forecast_scaledown);
tsdata.actualscaleup = merge(tsdata.actual,tsdata.forecast_scaleup);
tsdata.actualscaledown = merge(tsdata.actual,tsdata.forecast_scaledown);

lty=c("dotted", "dotted","dotted")
pdf('ActualForecast.pdf', height=5, width=7)
plot(tsdata.together, screens=1, lty=lty, pch="3", main="Actual Workload vs Scaleup Forecast vs Scaledown Forecast", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue","green"))
legend("bottomright", inset=.02, title="Legend", c("Actual","Scale Up Forecast","Scale Down Forecast"),lty=lty, col=c("red","blue","green"),cex=0.75)

plot(tsdata.actualscaleup, screens=1, lty=lty, pch="3", main="Actual Workload vs Scaleup Forecast", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue","green"))
legend("bottomright", inset=.02, title="Legend", c("Actual","Scale Up Forecast"),lty=lty, col=c("red","blue","green"),cex=0.75)

plot(tsdata.actualscaledown, screens=1, lty=lty, pch="3", main="Actual Workload vs Scaledown Forecast", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","green"))
legend("bottomright", inset=.02, title="Legend", c("Actual","Scale Down Forecast"),lty=lty, col=c("red","green"),cex=0.75)
dev.off()
lty=c("dotted", "dotted","dotted")
tiff('ScaleUpForecast.tiff',res=500, compression = "lzw", height=5, width=7, units="in")
plot(tsdata.actualscaleup, screens=1, lty=lty, pch="3", main="Actual Workload vs Scaleup Forecast", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue"))
legend("bottomright", inset=.02, title="Legend", c("Actual","Scale Up Forecast"),lty=lty, col=c("red","blue","green"),cex=0.75)
dev.off()

tiff('ScaleDownForecast.tiff',res=500, compression = "lzw", height=5, width=7, units="in")
plot(tsdata.actualscaledown, screens=1, lty=lty, pch="3", main="Actual Workload vs Scaledown Forecast", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue"))
legend("bottomright", inset=.02, title="Legend", c("Actual","Scale Down Forecast"),lty=lty, col=c("red","blue"),cex=0.75)
dev.off()

acc_scale_up = read.csv("accuracy_scaleup.log");
head = c("ME","RMSE","MAE","MPE","MAPE","MASE","ACF1");
colnames(acc_scale_up) = head
tiff('ScaleUpAcc.tiff',res=500, compression = "lzw", height=5, width=5, units="in")
boxplot(summary(acc_scale_up$MAPE), main="Box plot of Scale up Forecast Error", ylab="MAPE Error in Percentage")
dev.off()

acc_scale_down = read.csv("accuracy_scaledown.log");
head = c("ME","RMSE","MAE","MPE","MAPE","MASE","ACF1");
colnames(acc_scale_down) = head
tiff('ScaleDownAcc.tiff',res=500, compression = "lzw", height=5, width=5, units="in")
boxplot(summary(acc_scale_down$MAPE), main="Box plot of Scale down Forecast Error", ylab="MAPE Error in Percentage")
dev.off()

actual_header = c("UnixTimeStamp","ActualWorkload");
workload = read.csv(WORKLOAD,sep=",",header=F);
colnames(workload)  <- actual_header; 
workload$PosxTime= as.POSIXct(workload$UnixTimeStamp, origin="1970-01-01");
tsdata.completeworkload = zoo(workload$ActualWorkload,workload$PosxTime);

tiff('CompleteWorkload.tiff',res=500, compression = "lzw", height=5, width=7, units="in")
plot(tsdata.completeworkload, screens=1, lty=lty, pch="3", main="Complete Dataset", xlab="Time (in Hours)", ylab="Number of user requests", col="red")
legend("bottomright", inset=.02, title="Legend", c("User requests"),lty=lty, col=c("red","blue"),cex=0.75)
dev.off()

tiff('CompleteWithForecast.tiff',res=500, compression = "lzw", height=5, width=7, units="in")
plot(tsdata.completeworkload, screens=1, lty=lty, pch="3", main="Complete Dataset", xlab="Time (in Hours)", ylab="Number of user requests", col="red")
lines(tsdata.forecast_scaleup,lty=lty,pch="3",col="blue")
abline(v=2500)
legend("topright", inset=.02, title="Legend", c("User requests","User request forecast"),lty=lty, col=c("red","blue"),cex=0.75)
dev.off()



