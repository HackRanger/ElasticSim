Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)
library(zoo)
source("config.r");

billing_header = c("UnixTimeStamp","ActiveSessions","VmDemand","VmActive","VmBilled");
sim_log= read.csv(SYSTEM_LOG,sep=",",header=F);
forecastdata_scaleup=
colnames(sim_log)  <- billing_header
sim_log$StampToPosxTime = as.POSIXct(sim_log$UnixTimeStamp, origin="1970-01-01")
tsdata.userrequest = zoo(sim_log$ActiveSessions,sim_log$StampToPosxTime)
tsdata.vmdemand = zoo(sim_log$VmDemand,sim_log$StampToPosxTime)
tsdata.vmactive = zoo(sim_log$VmActive,sim_log$StampToPosxTime)
tsdata.vmbilling = zoo(sim_log$VmBilled,sim_log$StampToPosxTime)
tsdata.merged = merge(tsdata.userrequest,tsdata.vmdemand,tsdata.vmactive,tsdata.vmbilling)
tsdata.capacity = merge(tsdata.userrequest,tsdata.vmdemand*120,tsdata.vmactive*120,tsdata.vmbilling*120)

pdf("simulation_graphs.pdf")
plot(tsdata.userrequest, screens=1, pch=c(1),lty=c(3),main="Workload", xlab="Time", ylab="Number of user requests",col=c("red"),ylim=c(0, 1800))
abline(h=c(max(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="red")
abline(h=c(min(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="blue")
abline(h=c(mean(sim_log$VmDemand*120)), lwd=1.5, lty=2, col="green")
legend("topright", inset=.02, title="Legend", c("Request","Minimum Request","Average Request", "Maximum Request"),lty=c(3,2,2,2), col=c("red","blue","green","red"),cex=0.75)


plot(tsdata.capacity, screens=1, lty=c(3), pch="3", main="Workload", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue","green","black"))
legend("bottomright", inset=.02, title="Legend", c("Request","VM Demand","VM Active", "VM Billing"),lty=c(3,2,2,2), col=c("red","blue","green","black"),cex=0.75)

plot(tsdata.capacity[1:180], screens=1, lty=c(3), pch="3", main="Workload", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue","green","black"))
legend("bottomright", inset=.02, title="Legend", c("Request","VM Demand","VM Active", "VM Billing"),lty=c(3,2,2,2), col=c("red","blue","green","black"),cex=0.75)

plot(tsdata.capacity[1000:1180], screens=1, lty=c(3), pch="3", main="Workload", xlab="Time (in Hours)", ylab="Number of user requests", col=c("red","blue","green","black"))
legend("bottomright", inset=.02, title="Legend", c("Request","VM Demand","VM Active", "VM Billing"),lty=c(3,2,2,2), col=c("red","blue","green","black"),cex=0.75)

dev.off()
