library("xtable")
fit.table <- xtable(aov(fit))
MSE = format(sum(fit$residuals^2)/fit$df.residual, digit=2)
print(fit.table)
