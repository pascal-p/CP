
source("support/shared/utils.R")

fnameModel <- function(model=paste0("model_", perc, "p_training"), threshold=3, key='') {
  paste0(model,
         ifelse(threshold >= 1,
                paste0("_pruned_12345ngrams_thr_", threshold), "12345ngrams"),
         key,   # _sbo or _kn
         ".RData")
}

loadModel <- function(perc=10, model=paste0("model_", perc, "p_training"), 
                      srcPath="en_US/NonSpellChecked", threshold=3, key='', VERBOSE=F) {
  fname <- fnameModel(model, threshold, key)
  # load data
  if (VERBOSE) {
    cat(sprintf("%s - Loading from %s\n", tstmp(), fname))
    withTiming(load(paste(srcPath, fname, sep="/")))
  } else {
    load(paste(srcPath, fname, sep="/"))
  }
  if (exists("dts")) {
    if (VERBOSE) { statSz(dts) }
  } else {
    if (VERBOSE) { statSz(list(dt.5grams, dt.4grams, dt.3grams, dt.2grams, dt.1grams)) }
    dts <- list(dt.1grams=dt.1grams, 
                dt.2grams=dt.2grams, 
                dt.3grams=dt.3grams,
                dt.4grams=dt.4grams, 
                dt.5grams=dt.5grams)
    rm(list=c("dt.1grams", "dt.2grams", "dt.3grams", "dt.4grams", "dt.5grams"))
  }
  return(dts)  
}

statSz <- function(dtLst) {
  v <- vapply(dtLst, function(dt) { object.size(dt) }, numeric(1)) 
  tot <- sum(v)
  n <- length(v)
  
  cat(sprintf("\tTotal size:     %15.2f bytes\n", tot))
  for (ix in 1:n) {
    cat(sprintf("\tdt.%dgrams size: %15.2f bytes\n", n+1-ix, v[[ix]]))
  }
  return(0)
}

## Special case for testing purpose based on article: 
## "Implementation of Modified Kneser-Ney Smoothing on Top of Generalized Language Models for Next Word Prediction"

loadCsvFiles <- function(srcPath="./test") {
  fileLst <- list.files(path=srcPath, 
                        pattern=paste0("^.+\\.csv$"), 
                        full.names=T, all.files=F)
  # order bigram, trigram, and unigram
  dfLst <- NULL
  for (file in fileLst) {
    cat(paste0("1 - Loading file: ", file, "\n"))
    df    <- read.csv(file, header=T, sep=",", quote="\"", dec=".", stringsAsFactors=F) 
    print(head(df, 3))
    dfLst <- c(dfLst, list(df))
  }
  cat(paste0("2- Length ", length(dfLst), "\n"))
  
  dt2 <- data.table(ngram=dfLst[[1]]$ngram, freq=dfLst[[1]]$freq)
  dt3 <- data.table(ngram=dfLst[[2]]$ngram, freq=dfLst[[2]]$freq)
  dt1 <- data.table(ngram=dfLst[[3]]$ngram, freq=dfLst[[3]]$freq)
  
  return(list(dt1, dt2, dt3))
}
