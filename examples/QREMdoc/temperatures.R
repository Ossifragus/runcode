# quantile regression application - temperature data, Las Vegas, NV

library("QREM")
library("lme4")
dat <- read.csv("LasVegas.csv", header=TRUE)
dat$DATE <- as.Date(dat$DATE, "%Y-%m-%d")
dat$year <- as.numeric(substring(dat$DATE, 1, 4))
dat$month <- factor(months(dat$DATE), levels = month.name)
dat$yday <- as.numeric(format(dat$DATE,"%j"))
dat$sinedoy <- sin(2*pi*(dat$yday-11)/365-pi/2)

linmodMin <- TMIN ~ sinedoy + year + (1|month)
linmodMax <- TMAX ~ sinedoy + year + (1|month)

qremFit10min <- QREM(lmer,linmodMin, dat,qn = 0.1)
qrdg10 <- QRdiagnostics(dat$year, "year (min. temp.)", qremFit10min$ui, qn=0.1, filename = "generated/LVmintemp.pdf")

qremFit90max <- QREM(lmer,linmodMax, dat,qn = 0.9)
qrdg90 <- QRdiagnostics(dat$year, "year (max. temp.)", qremFit90max$ui, qn=0.9, filename = "generated/LVmaxtemp.pdf")

# can also use a generalized additive model (gam), but the fit it slower
#  gam10fit <- QREM(gam, TMIN ~ s(yday,4) + year + month, data=dat, qn=0.1)
