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
qrdg <- matrix(0,nrow=n, ncol=length(qns))
xqs <- quantile(x, probs = (1:(L-1))/L)
names(xqs) <- c()
qqp  <- matrix(0, nrow=length(xqs), ncol=length(qns))
qqp2 <- matrix(0, nrow=length(xqs), ncol=length(qns))
i <- 1
for (qn in qns) {
  qremFit <- QREM(lm, linmod=y~x+I(x^2), df=data.frame(y,x,x^2), qn=qn)
  qrdg <- QRdiagnostics(x, "x",qremFit$ui, qn,  plot.it = ifelse(abs(qn-0.1) < 1e-6, TRUE, FALSE), filename="tmp/sim23q10correct.pdf")
  for (j in 1:(L-1)) {
    qqp[j,i] <- length(which(qrdg$y < xqs[j])) / length(which(qrdg$x < xqs[j]))
  }
  
  qremFit <- QREM(lm, linmod=y~x, df=data.frame(y,x,x^2), qn=qn)
  qrdg <- QRdiagnostics(x, "x",qremFit$ui, qn, plot.it = ifelse(abs(qn-0.1) < 1e-6, TRUE, FALSE), filename="tmp/sim23q10incorrect.pdf")
  for (j in 1:(L-1)) {
    qqp2[j,i] <- length(which(qrdg$y < xqs[j])) / length(which(qrdg$x < xqs[j]))
  }
  i <- i+1
}
flatQQplot(x,xqs,qqp,qns, L=21, filename = "tmp/flatQQsim23q10correct.pdf")
flatQQplot(x,xqs,qqp2,qns, L=21, filename = "tmp/flatQQsim23q10incorrect.pdf")
