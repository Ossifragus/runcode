# Run this to install the packages: `import Pkg; Pkg.add("Distributions")`
using Random, Distributions

Random.seed!(2);
z = Normal(0, 1);
x = rand(z, 10);
n = length(x);
a = round(Int64, sum(exp.(x.^3))) * sum(1:n) + round(Int64, sum(abs.(x).^(2.383))^pi*pi);
b = round(Int64, sum(exp.(x.^4))) - sum(1:5n) - round(Int64, sum(abs.(x))/3);
res = (a,b)
