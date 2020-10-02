library(rpart)
#library(rpart.plot)
library(randomForest)
library(e1071)
library(kableExtra)

loadData <- function() {
  loc <- "http://archive.ics.uci.edu/ml/machine-learning-databases/"
  ds  <- "breast-cancer-wisconsin/breast-cancer-wisconsin.data"
  url <- paste(loc, ds, sep="")
  breast <- read.table(url, sep=",", header=FALSE, na.strings="?")
  names(breast) <- c("ID", "clumpThickness", "sizeUniformity",
                     "shapeUniformity", "maginalAdhesion", 
                     "singleEpithelialCellSize", "bareNuclei", 
                     "blandChromatin", "normalNucleoli", "mitosis", "class")
  df <- breast[-1]
  df$class <- factor(df$class, levels=c(2,4), labels=c("benign", "malignant"))
  df
}


trainingSubset  <- function(df, pctTraining=0.7, seed=1234) {
  set.seed(seed)
  sample(nrow(df), pctTraining*nrow(df))
}


fitModel <- function(method, df.train) {
  switch(method,
         logreg = glm(class~., data=df.train, family=binomial()),
         dtree = prune(rpart(class ~ ., data=df.train, method="class",parms=list(split="information")), cp=.0125),
         rf = randomForest(class~., data=df.train,na.action=na.roughfix, importance=TRUE),
         svm = svm(class~., data=df.train)
  )
}


predictOutcome <- function(method, fittedModel, df.validate) {
  switch(method,
         logreg = factor(predict(fittedModel, na.omit(df.validate), type="response") > 0.5, levels=c(FALSE, TRUE), labels=c("benign", "malignant")),
         dtree = predict(fittedModel, na.omit(df.validate), type="class"),
         rf = predict(fittedModel, na.omit(df.validate)),
         svm = predict(fittedModel, na.omit(df.validate))
  )
}

classifyCancer <- function(dframe, method, pctTraining) {
  trainset <- sort(trainingSubset(dframe,pctTraining))
  fittedModel <- fitModel(method, dframe[trainset,])
  df.validate <- dframe[-trainset,]
  pred <- predictOutcome(method, fittedModel, df.validate)
  perf <- table(na.omit(df.validate)$class, pred, dnn=c("Actual", "Predicted"))
  gsub(">\\s*",">",kable(perf), perl=TRUE)
}

dfAll <- loadData()

# # table(df.train$class)
# table(df.validate$class)
