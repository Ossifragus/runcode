library(SEMMS)
library(QREM)
##########################################################################
# Simulation 5 in table A4 - variable selection with SEMMS

coefs <- c(1, -3,2,2,-1,-2)
n <- 200
X <- matrix(runif(n*6),nrow=n, ncol=6)
X[,1] <- rep(1,n)
colnames(X) <- c("const", paste("X",1:5,sep=""))
set.seed(11002)
y <- X%*%as.matrix(coefs,ncol=1,nrow=6) + rnorm(n, 0, 0.1+X[,2])
dframe <- data.frame(y,X[,-1], matrix(rnorm((500-ncol(X)+1)*n,0,0.1), nrow=n, ncol=(500-ncol(X)+1)))
save(dframe, file="generated/sim05.RData")

qn <- 0.25
res <- QREM_vs("generated/sim05.RData", 1, 2:501, qn=qn)
dfsemms <- dframe[,c(1, 1+res$fittedSEMMS$gam.out$nn)]
qremFit <- QREM(lm, y~., dfsemms, qn=qn)
ests <- rbind(qremFit$coef$beta, sqrt(diag(bcov(qremFit,linmod=y~., df=dfsemms, qn=0.2))))
rownames(ests) <- c("Estimate","s.d. (Bahadur)")
library(xtable)
print(xtable(ests, digits=3), file="generated/SimA4_5.tex")

qrdg <- QRdiagnostics(dfsemms[,2], "X1",qremFit$ui, qn, filename="generated/simVS5.pdf")
