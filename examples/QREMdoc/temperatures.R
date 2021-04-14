# quantile regression application - temperature data, Las Vegas, NV

library("QREM")
dat <- read.csv("LasVegas.csv", header=TRUE)
dat$DATE <- as.Date(dat$DATE, "%Y-%m-%d")
dat$year <- as.numeric(format(dat$DATE,"%Y"))
dat$month <- factor(months(dat$DATE), levels = month.name)
dat$yday <- as.numeric(format(dat$DATE,"%j"))
dat$sinedoy <- sin(2*pi*(dat$yday-11)/365-pi/2)

linmodMin <- TMIN ~ sinedoy + year + (1|month)
linmodMax <- TMAX ~ sinedoy + year + (1|month)

qremFit10min <- QREM(lmer,linmodMin, dat,qn = 0.1)
qrdg10 <- QRdiagnostics(dat$year, "year (min. temp.)", qremFit10min$ui, qn=0.1, filename = "tmp/LVmintemp.pdf")

qremFit90max <- QREM(lmer,linmodMax, dat,qn = 0.9)
qrdg90 <- QRdiagnostics(dat$year, "year (max. temp.)", qremFit90max$ui, qn=0.9, filename = "tmp/LVmaxtemp.pdf")

qns <- seq(0.1,0.9,by=0.1)
x <- unique(sort(dat$year))
L <- 10
evalx <- quantile(x,(1:(L-1))/L)
xqs <- quantile(x, probs = (1:(L-1))/L)
names(xqs) <- c()
qqp  <- matrix(0, nrow=length(xqs), ncol=length(qns))
for (i in 1:length(qns)) {
  qn <- qns[i]
  qremFit <- QREM(lmer, linmodMin, dat,qn = qn)
  qrdg <- QRdiagnostics(dat$year, "year",qremFit$ui, qn, plot.it = F)
  for (j in 1:(L-1)) {
    qqp[j,i] <- length(which(qrdg$y < xqs[j])) / length(which(qrdg$x < xqs[j]))
  }
}
flatQQplot(x,xqs,qqp,qns, L=21, filename = "tmp/LVmin.pdf")

# can also use a generalized additive model (gam), but the fit it slower
#  gam10fit <- QREM(gam, TMIN ~ s(yday,4) + year + month, data=dat, qn=0.1)
