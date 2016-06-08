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

tiff("workloadforsim.tiff",res=500, compression = "lzw", height=5, width=8, units="in")
plot(tsdata.userrequest, screens=1, pch=c(1),lty=c(3),main="Workload", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(0, 1800))
abline(h=c(max(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="red")
abline(h=c(min(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="blue")
abline(h=c(mean(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="green")
axis(4, at= c(max(sim_log$VmDemand*120),mean(sim_log$VmDemand*120),min(sim_log$VmDemand*120)),labels=round(c(max(sim_log$VmDemand),mean(sim_log$VmDemand),min(sim_log$VmDemand)),digits = 0),col.axis="blue", las=2, cex.axis=0.7, tck=-.01);
mtext("Number of VM", side=4, col="blue");
legend("topright", inset=.02, title="Legend", c("Request","Minimum Request","Average Request", "Maximum Request"),lty=c(3,2,2,2), col=c("red","blue","green","red"),cex=0.75)
dev.off();


tiff("highlevelvmscaling.tiff",res=500, compression = "lzw", height=5, width=8, units="in")
plot(tsdata.forecastedscaleup, screens=1, pch=c(1),lty=c(3),main="", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(0, 1800))
lines(tsdata.vmactive*120, lwd=1.5, lty=2, col="green")
axis(4, at= tsdata.vmactive*120,labels=tsdata.vmactive,col.axis="blue", las=2, cex.axis=0.7, tck=-.01);
mtext("Number of VM actively serving", side=4, col="blue");
legend("topright", inset=.02, title="Legend", c("Request","VM Active"),lty=c(3,2,2,2), col=c("red","green"),cex=0.75)
dev.off();

i=1;
while(i<30){
j=i+20;
tiff(paste("autoscalingdiag", i ,".tiff",sep=""),res=500, compression = "lzw", height=5, width=7, units="in")
plot(tsdata.forecastedscaleup[i:j], screens=1, xaxt = "n",pch=c(1),lty=c(3),main="", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(1:1800))
drawTimeAxis(tsdata.forecastedscaleup[i:j], tick.tstep="minutes", lab.tstep="minutes") 
lines(tsdata.vmbilling[i:j]*120, lwd=1.5, lty=3, col="blue")
lines(tsdata.vmactive[i:j]*120, lwd=1.5, lty=3, col="green")
axis(4, at= tsdata.vmactive[i:j]*120,labels=tsdata.vmactive[i:j],col.axis="blue", las=2, cex.axis=0.7, tck=-.01);
mtext("Number of VM actively serving", side=4, col="blue");
legend("topright", inset=.02, title="Legend", c("Request","VM's Billing","VM's Active"),lty=c(3,2,2,2), col=c("red","blue","green"),cex=0.75)
dev.off();
i=i+20;
}

i=1;
while(i<2500){
j=i+180;
tiff(paste("autoscalingdiag", i ,".tiff",sep=""),res=500, compression = "lzw", height=5, width=5, units="in")
plot(tsdata.forecastedscaleup[i:j], screens=1, xaxt = "n",pch=c(1),lty=c(3),main="", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(1:1800))
drawTimeAxis(tsdata.forecastedscaleup[i:j], tick.tstep="hours", lab.tstep="hours") 
lines(tsdata.vmbilling[i:j]*120, lwd=1.5, lty=3, col="blue")
lines(tsdata.vmactive[i:j]*120, lwd=1.5, lty=3, col="green")
axis(4, at= tsdata.vmactive[i:j]*120,labels=tsdata.vmactive[i:j],col.axis="blue", las=2, cex.axis=0.7, tck=-.01);
mtext("Number of VM actively serving", side=4, col="blue");
legend("topright", inset=.02, title="Legend", c("Request","VM's Billing","VM's Active"),lty=c(3,2,2,2), col=c("red","blue","green"),cex=0.75)
dev.off();
i=i+180;
}

i=1;
while(i<2500){
j=i+180;
tiff(paste("slaviolation", i ,".tiff",sep=""),res=500, compression = "lzw", height=5, width=5, units="in")
plot(tsdata.forecastedscaleup[i:j], screens=1, xaxt = "n",pch=c(1),lty=c(3),main="", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(1:1800))
plot(tsdata.userrequest[i:j], screens=1, pch=c(1),lty=c(3),main="", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(1:1800))
lines(tsdata.forecastedscaleup[i:j], lwd=1.5, lty=2, col="blue")
lines(tsdata.vmactive[i:j]*120, lwd=1.5, lty=2, col="green")
axis(4, at= tsdata.vmactive[i:j]*120,labels=tsdata.vmactive[i:j],col.axis="blue", las=2, cex.axis=0.7, tck=-.01);
mtext("Number of VM actively serving", side=4, col="blue");
legend("topright", inset=.02, title="Legend", c("Request","Forecasted","Active"),lty=c(3,2,2,2), col=c("red","blue","green"),cex=0.75)
i=i+180;
dev.off()
}


tiff(paste("boxplotslaviolation", i ,".tiff",sep=""),res=500, compression = "lzw", height=5, width=5, units="in")
slaviolation=tsdata.actual - (tsdata.vmactive * 120);
data=subset(slaviolation,slaviolation>0);
boxplot(summary(coredata(data)), main="Box plot of SLA violations", ylab="Number of user facing SLA violation")
dev.off()
