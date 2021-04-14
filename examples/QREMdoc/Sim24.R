library(QREM)

##########################################################################
# Simulation 24 in table A3
# A two-way interaction model between two continuous variables, and an
#  increasing variance. A categorical variable is also included in the data.

n <- 10000
x <- seq(0,1,length.out = n)
x2 <- x[sample(n)]
x3 <- factor(c(rep("C",5000), rep("T1", 3000), rep("T2",2000)))
y <- 4*x*x2 + rnorm(n,0,0.1+0.2*x)

L <- 20
qns <- seq(0.05,0.95,by=0.05)
xqs <- quantile(x, probs = (1:(L-1))/L)
names(xqs) <- c()
qqp  <- matrix(0, nrow=length(xqs), ncol=length(qns))
qqp2 <- matrix(0, nrow=length(xqs), ncol=length(qns))
i <- 1
for (qn in qns) {
  qremFit <- QREM(lm, linmod=y~x*x2 +x3, df=data.frame(y,x,x2, x3), qn=qn)
  qrdg <- QRdiagnostics(x, "x",qremFit$ui, qn, plot.it = ifelse(qn == 0.1, T, F))
  dgx3 <- QRdiagnostics(x3, "x3",qremFit$ui, qn,  plot.it = ifelse(qn == 0.1, T, F), filename="tmp/sim24q10correct.pdf")
  for (j in 1:(L-1)) {
    qqp2[j,i] <- length(which(qrdg$y < xqs[j])) / length(which(qrdg$x < xqs[j]))
  }

  qremFit <- QREM(lm, linmod=y~x+x2+x3, df=data.frame(y,x,x2, x3), qn=qn)
  qrdg <- QRdiagnostics(x, "x",qremFit$ui, qn,  plot.it = ifelse(qn == 0.1, T, F))
  dgx3 <- QRdiagnostics(x3, "x3",qremFit$ui, qn,  plot.it = ifelse(qn == 0.1, T, F), filename="tmp/sim24q10incorrect.pdf")
  for (j in 1:(L-1)) {
    qqp[j,i] <- length(which(qrdg$y < xqs[j])) / length(which(qrdg$x < xqs[j]))
  }
  i <- i+1
}
flatQQplot(x,xqs,qqp,qns)
flatQQplot(x,xqs,qqp2,qns)

library(xtable)
qremFit <- QREM(lm, linmod=y~x*x2 +x3, df=data.frame(y,x,x2, x3), qn=qn)
estBS <- boot.QREM(lm, linmod=y~x*x2+x3, df=data.frame(y,x,x2,x3), qn=0.2, n=length(y), B=50)
ests <- rbind(qremFit$coef$beta,apply(estBS,2, sd), sqrt(diag(bcov(qremFit,linmod=y~x*x2+x3, df=data.frame(y,x,x2,x3), qn=0.2))))
rownames(ests) <- c("Estimate","Bootstrap","Bahadur")
print(xtable(ests))
