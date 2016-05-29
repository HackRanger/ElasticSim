Sys.setlocale("LC_TIME", "C");
library(lubridate);
library(TTR);
library(fpp)
library(forecast)



prediction=function (tsdata, horizon=1) {
  tseries=tsdata;
  arimaPredicted=c();
  arimaFit=auto.arima(tseries)
  pred=forecast(arimaFit,h=horizon)
  accuracy(pred)
  arimaPredicted = pred$mean
  return(arimaPredicted)
}

  generatePredictions = function() {
    BASE = '/Users/subramanya/Documents/workspace/elasticapps/logs/'
    billing_header = c("UnixTimeStamp","ActiveSessions");
    user_req = read.csv(paste(BASE,"rtc_last_dataset.csv", sep=""),  sep="," , header=F);
    colnames(user_req)  <- billing_header
    user_req$StampToPosxTime = as.POSIXct(user_req$UnixTimeStamp, origin="1970-01-01");
    library(zoo);
    tsdata.userrequest = zoo(user_req$ActiveSessions,user_req$StampToPosxTime);
    horizon=5;
    start=1;
    arimaPredicted=c();
    vmactive=c();
    for (i in seq(1440,2880,5)) {
      arimaWindow = prediction(tsdata.userrequest[1:i], horizon);
      arimaPredicted = c(arimaPredicted,arimaWindow);
    }
    return(arimaPredicted)
  }
  BASE = '../logs/'
  billing_header = c("UnixTimeStamp","ActiveSessions");
  user_req = read.csv(paste(BASE,"rtc_last_dataset.csv", sep=""),  sep="," , header=F);
  colnames(user_req)  <- billing_header
  user_req$StampToPosxTime = as.POSIXct(user_req$UnixTimeStamp, origin="1970-01-01");
  library(zoo);
  tsdata.userrequest = zoo(user_req$ActiveSessions,user_req$StampToPosxTime);
arimaPredicted = generatePredictions();
PredictedData = zoo(arimaPredicted,user_req$StampToPosxTime[1455:2895])
combinedData = merge(PredictedData,tsdata.userrequest[1:2895])


# Plots: User request
tiff('sampleworkload.tiff', res=600, compression = "lzw", height=5, width=5, units="in")
opar <- par(no.readonly=TRUE)
# par(mfrow=c(2,1))
plot(tsdata.userrequest[1:8440],col="blue",main="Workload", xlab="Time (in Days)", ylab="Number of user requests")
par(opar)
dev.off()

# Plots: User request
tiff('forecasted.tiff', res=600, compression = "lzw", height=5, width=5, units="in")
opar <- par(no.readonly=TRUE)
plot(combinedData,screens=1, pch="3", main="Actual Workload and Forecast Workload", xlab="Time (in Days)", ylab="Number of user requests", col=c("red","blue","green","black"))
par(opar)
dev.off()

for (i in seq(1440,2880,5)) {
  tseries=tsdata.userrequest[1:i];
  arimaFit=auto.arima(tseries)
  pred=forecast(arimaFit,h=5)
  print(accuracy(pred))
}
