# R code with labeled chunks used by the ChunkTest example.
# Each chunk is self-contained so it can be shown or run independently.

set.seed(42)
n <- 50
x <- rnorm(n, mean = 5, sd = 2)

# label===chunk01
cat("n =", n, "\n")
# ===end

# label===chunk02
cat("mean =", round(mean(x), 3), "\n")
# ===end

# label===chunk03
cat("sd =", round(sd(x), 3), "\n")
# ===end

# label===chunk04
cat("min =", round(min(x), 3), "\n")
# ===end

# label===chunk05
cat("max =", round(max(x), 3), "\n")
# ===end

# label===chunk06
cat("median =", round(median(x), 3), "\n")
# ===end

# label===chunk07
q <- quantile(x, c(0.25, 0.75))
cat("Q1 =", round(q[1], 3), "\n")
# ===end

# label===chunk08
cat("Q3 =", round(q[2], 3), "\n")
# ===end

# label===chunk09
cat("IQR =", round(IQR(x), 3), "\n")
# ===end

# label===chunk10
cat("var =", round(var(x), 3), "\n")
# ===end

# label===chunk11
cat("range =", round(diff(range(x)), 3), "\n")
# ===end

# label===chunk12
cat("sum =", round(sum(x), 3), "\n")
# ===end

# label===chunk13
cat("skewness proxy =", round(mean((x - mean(x))^3) / sd(x)^3, 3), "\n")
# ===end

# label===chunk14
cat("kurtosis proxy =", round(mean((x - mean(x))^4) / sd(x)^4, 3), "\n")
# ===end

# label===chunk15
cat("cv =", round(sd(x) / mean(x), 3), "\n")
# ===end

# label===chunk16
cat("se =", round(sd(x) / sqrt(n), 3), "\n")
# ===end

# label===chunk17
ci <- mean(x) + c(-1, 1) * 1.96 * sd(x) / sqrt(n)
cat("95% CI: [", round(ci[1], 3), ",", round(ci[2], 3), "]\n")
# ===end

# label===chunk18
cat("All done.\n")
# ===end
