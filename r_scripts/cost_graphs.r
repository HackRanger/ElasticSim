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
rownames(mat) = c("opt1","opt2","opt3","opt4","opt5","opt6","opt7")
tmat=t(mat)

pdf("cost_graphs.pdf",width=20,height=10)
opar <- par(no.readonly=TRUE)
bp=barplot(tmat,main="Cost of each option to reserve instance",xlab="Options", ylab="Cost in USD",col=c(2:7),beside=T,legend=colnames(mat),horiz = F)
text(bp, 0, round(tmat, 1),cex=1.5,pos=3,offset=19,srt = 90) 
par(opar)
dev.off()

