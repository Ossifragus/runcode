set.seed(0) ## fix the random number
x = rnorm(100)
y = 1+x+rnorm(100)
fit = lm(y~x)
print(summary(fit))
