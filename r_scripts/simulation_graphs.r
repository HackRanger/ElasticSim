Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)
library(zoo)
setwd("/Users/subramanya/Dropbox/Project/Code/ElasticSim/r_scripts");
source("config.r");
billing_header = c("UnixTimeStamp","ActiveSessions","VmDemand","VmActive","VmBilled");
sim_log= read.csv(SYSTEM_LOG,sep=",",header=F);
forecastdata_scaleup=read.csv(FORECAST_SCALEUP_WORKLOAD,sep=",",header=F);
forecast_header=c("UnixTimeStamp","ForecastedSessions");
colnames(sim_log)  <- billing_header
colnames(forecastdata_scaleup)  <- forecast_header;
sim_log$StampToPosxTime = as.POSIXct(sim_log$UnixTimeStamp, origin="1970-01-01")
tsdata.userrequest = zoo(sim_log$ActiveSessions,sim_log$StampToPosxTime)
tsdata.vmdemand = zoo(sim_log$VmDemand,sim_log$StampToPosxTime)
tsdata.vmactive = zoo(sim_log$VmActive,sim_log$StampToPosxTime)
tsdata.vmbilling = zoo(sim_log$VmBilled,sim_log$StampToPosxTime)
tsdata.merged = merge(tsdata.userrequest,tsdata.vmdemand,tsdata.vmactive,tsdata.vmbilling)
tsdata.forecastedscaleup=zoo(forecastdata_scaleup$ForecastedSessions,sim_log$StampToPosxTime);
tsdata.capacity = merge(tsdata.userrequest,tsdata.forecastedscaleup,tsdata.vmdemand*120,tsdata.vmactive*120,tsdata.vmbilling*120)

pdf("simulation_graphs.pdf")
plot(tsdata.userrequest, screens=1, pch=c(1),lty=c(3),main="Workload", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(0, 1800))
abline(h=c(max(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="red")
abline(h=c(min(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="blue")
abline(h=c(mean(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="green")
legend("topright", inset=.02, title="Legend", c("Request","Minimum Request","Average Request", "Maximum Request"),lty=c(3,2,2,2), col=c("red","blue","green","red"),cex=0.75)

plot(tsdata.userrequest, screens=1, pch=c(1),lty=c(3),main="Workload", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(0, 1800))
lines(tsdata.forecastedscaleup, lwd=1.5, lty=2, col="blue")
lines(tsdata.vmactive*120, lwd=1.5, lty=2, col="green")
legend("topright", inset=.02, title="Legend", c("Request","Forecasted","Active"),lty=c(3,2,2,2), col=c("red","blue","green"),cex=0.75)

i=1;
while(i<2500){
j=i+180;
plot(tsdata.userrequest[i:j], screens=1, pch=c(1),lty=c(3),main="Workload", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(1:1800))
lines(tsdata.forecastedscaleup[i:j], lwd=1.5, lty=2, col="blue")
lines(tsdata.vmactive[i:j]*120, lwd=1.5, lty=2, col="green")
legend("topright", inset=.02, title="Legend", c("Request","Forecasted","Active"),lty=c(3,2,2,2), col=c("red","blue","green"),cex=0.75)
i=i+180;
}



dev.off()
