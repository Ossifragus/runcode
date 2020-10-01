
# read the data from https://ourworldindata.org/obesity#what-share-of-adults-are-obese
obesity <- read.csv("Data/share-of-adults-defined-as-obese.csv",header=TRUE)
sort(unique(obesity$Code)) # printed to the output, but not used in the tex file
# convert to "wide" format:
widedata <- reshape(obesity, idvar="Entity", v.names = "Prevalence.of.obesity..both.sexes....WHO..2019.",timevar = "Year", direction = "wide")
colnames(widedata)[-(1:2)] <- seq(1975,2016)
rownames(widedata) <- widedata$Entity
