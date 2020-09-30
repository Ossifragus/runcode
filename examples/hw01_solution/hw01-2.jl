using DelimitedFiles, Statistics
# You need to make sure the data file is in the working directory
# With Linux and Mac, it is like: cd("/home/homework/hw01/")
# With Windows, it is like: cd("C:\\homework\\hw01")
dat = readdlm("hw01.csv", ',', Any, '\n')
x = dat[:,1]
y = dat[:,2]
corr = round(cor(x, y), digits=5)
using Plots
p = plot(x, y, seriestype=:scatter, axis=false, legend=false, title="Hello")
savefig(p, "face.pdf")
