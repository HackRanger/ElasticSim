Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)
library(zoo)
setwd("/Users/subramanya/Dropbox/Project/Code/ElasticSim/r_scripts");
source("config.r");
cost_header = c("baseline","ricost","odicost","totalcost","ricount","odicount");
cost_log = read.csv(COST_LOG,sep=",",header=F);
colnames(cost_log)  <- cost_header; 
mat = as.matrix(cost_log)

name = c()
j = dim(mat)


for(i in seq(1,j[1]))
{
	temp = paste("option",as.character(i),sep="");
	name = c(name,temp)
}

rownames(mat) = name
tmat=t(mat)

wid = (j[1] * 10) / 7;

pdf("cost_graphs.pdf",width=wid,height=10)
opar <- par(no.readonly=TRUE)
bp=barplot(tmat,main="Cost of each option to reserve instance",xlab="Options", ylab="Cost in USD",col=c(2:7),beside=T,legend=colnames(mat),horiz = F)
text(bp, 0, round(tmat, 1),cex=1.5,pos=3,offset=19,srt = 90) 
par(opar)
dev.off()

tiff("purchaseoption.tiff",res=500, compression = "lzw", height=10, width=12, units="in")
opar <- par(no.readonly=TRUE)
bp=barplot(tmat,main="Cost of each option to reserve instance",xlab="Options", ylab="Cost in USD",col=c(2:7),beside=T,legend=colnames(mat),horiz = F)
text(bp+0.4, 0, round(tmat, 1),cex=1.5,pos=3,offset=19,srt = 90) 
par(opar)
dev.off()


# Plots: Lifetime Graphs
tiff("vm_life_time.tiff",res=500, compression = "lzw", height=10, width=12, units="in")
lifetime_header = c("VMID","BillingStart","BillingEnd","ActiveStart","ActiveEnd","MinutesUsed","Cost");
vm_life_time = read.csv(VM_BILLING_HOURS_WITH_RI_LOG,  sep="," , header=F);
colnames(vm_life_time)  <- lifetime_header
vm_life_time$BillingStartPosxTime = as.POSIXct(vm_life_time$BillingStart, origin="1970-01-01")
vm_life_time$BillingEndPosxTime = as.POSIXct(vm_life_time$BillingEnd, origin="1970-01-01")
vm_life_time$ActiveStartPosxTime = as.POSIXct(vm_life_time$ActiveStart, origin="1970-01-01")
vm_life_time$ActiveEndPosxTime = as.POSIXct(vm_life_time$ActiveEnd, origin="1970-01-01")

tsdata=zoo(vm_life_time$VMID, vm_life_time$BillingStartPosxTime)
sorted_vm_life=vm_life_time[order(vm_life_time$VMID),]
tiff('vmlifetime.tiff', res=200, compression = "lzw", height=35, width=65, units="in")
opar <- par(no.readonly=TRUE)
plot(tsdata,type="n",xlim=c(sorted_vm_life[1,8], sorted_vm_life[1,9]+10000), ylim=c(1, 22),main="VM Lifetime Graph", xlab="Time (in Days)", ylab="VM ID",cex=5,cex.lab=3,cex.axis=3,cex.main=3,mgp=c(2,1,.5))
for (i in 1:21) {
  rect(sorted_vm_life[i,8],i,sorted_vm_life[i,9],i+1,border="blue",col="red")
  if(i==1)
  {
    text(sorted_vm_life[i,8],i+0.5,labels=paste("Mins Use:",sorted_vm_life[i,6],"Cost:$" , sorted_vm_life[i,7]),pos=4, cex=3)
  }
  else{
    text(sorted_vm_life[i,8],i+0.5,labels=paste("Mins Use:",sorted_vm_life[i,6],"Cost:$" , sorted_vm_life[i,7]),pos=4, cex=3)
 }
}
dev.off()


