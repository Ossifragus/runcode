library(QREM)

##########################################################################
# Simulation 25 in table A3 - A mixed model

n <- 100
tm <- 4
z <- kronecker(diag(1,n),rep(1,tm))
set.seed(71371)
x <- rep(c(1:tm)/tm,n) + rnorm(n*tm,0,2e-2)
u <- rnorm(n,0,0.5)
e <- rnorm(tm*n,0,0.1) 
y <- 2 + x + z%*%u + e
dframe <- data.frame(y,x,as.factor(rep(1:tm, n)),as.factor(kronecker(1:n,rep(1,tm))))
colnames(dframe) <- c("y","X","Z","S")
linmod <- y~X+(1|S)
qn <- 0.2
qremFit <- QREM(lmer,linmod, dframe, qn)
estBS <- boot.QREM(lmer,linmod, dframe, qn, n=nrow(dframe), B=50)
ests <- rbind(qremFit$coef$beta,apply(estBS,2, sd))
rownames(ests) <- c("Estimate","Bootstrap s.d.")
library(xtable)
print(xtable(ests))
