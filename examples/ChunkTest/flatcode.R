# R code in the current (flat) directory — tests that showChunk/runRChunk
# work when the source file has no subdirectory prefix.

# label===flat_hello
cat("hello from flat file\n")
# ===end

# label===flat_arithmetic
cat("2 + 2 =", 2 + 2, "\n")
# ===end
