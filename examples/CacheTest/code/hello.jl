# Julia code for CacheTest example.
# Chunks are self-contained so they can be run independently via the server.

# label===jl-sum
x = [2, 4, 6, 8, 10]
println(sum(x))
# ===end

# label===jl-mean
x = [2, 4, 6, 8, 10]
println(sum(x) / length(x))
# ===end

# label===jl-hello
println("Hello from Julia!")
# ===end
