pdf("generated/shareDelta.pdf",width = 4,height = 4)
plot(widedata$"1975",widedata$"2016"-widedata$"1975",ylim=c(0,40),col=0,xlab="Share obese in 1975",
     ylab="change in share obese from 1975 to 2016")
grid()
usarow <- which(widedata$Code == "USA")
text(widedata$"1975",widedata$"2016"-widedata$"1975",widedata$Code,cex=0.6,col="slateblue1")
text(widedata$"1975"[usarow],widedata$"2016"[usarow]-widedata$"1975"[usarow],col=2,cex=0.6,
     widedata$Code[usarow])
dev.off()
