library(QREM)

##########################################################################
# Simulation 23 in table A3.
# Quadratic mean model, increasing variance.
# Compare the fit of the correct model, y~x+I(x^2), with the incorrect,
#   linear model. Show diagnostic plots - Q-Q plot when qn=0.1, and
#   a flat diagnostic plot for all the quantiles, qns.
set.seed(21322)
n <- 2000
qns <- seq(0.05,0.95,by=0.05)
x <- seq(0,3,length.out = n)
L <- 20
y <- 6*x^2 + x +120 + rnorm(n, 0, 0.1+0.5*x)
qrfits1 <- qrfits2 <- list()
dat <- data.frame(y,x,x^2)
for (i in 1:length(qns)) {
  qrfits1[[i]] <- QREM(lm, linmod=y~x+I(x^2), df=dat, qn=qns[i])
  qrfits2[[i]] <- QREM(lm, linmod=y~x, df=dat, qn=qns[i])
}
qrdg10c <- QRdiagnostics(dat$x, "x", qrfits1[[2]]$ui, qn=0.1, plot.it=TRUE, filename = "generated/sim23q10correct.pdf")
qrdg10i <- QRdiagnostics(dat$x, "x", qrfits2[[2]]$ui, qn=0.1, plot.it=TRUE, filename = "generated/sim23q10incorrect.pdf")
pvals <- flatQQplot(dat=dat, cnum = 2, qrfits=qrfits1, qns=qns, maxm = 20, plot.it = TRUE, filename = "generated/flatQQsim23q10correct.pdf")
pvals <- flatQQplot(dat=dat, cnum = 2, qrfits=qrfits2, qns=qns, maxm = 20, plot.it = TRUE, filename = "generated/flatQQsim23q10incorrect.pdf")
