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

