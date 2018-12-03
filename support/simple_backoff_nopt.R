# require(quanteda)
require(data.table)

source("support/shared/clean_fun.R")
source("support/shared/load_model.R")
source("support/shared/san_input.R")

lookup <- function(lastw, dt) {
  dt_match  <- dt[.(lastw)] # using (default) setkey order
  num_match <- ifelse((is.null(dt_match) || is.na(dt_match[, score])),
                      0, dt_match[, .N])
  return(list(dt.match=dt_match, num.match=num_match))
}

lastw <- function(v, nth) {
  paste0(tail(v, nth), collapse=" ")
}

# from highest order n-grams
predict.NgramHO <- function(lastw, dt, dt.lo, topr, lambda=1.0, VERBOSE=T) {
  r <- lookup(lastw, dt)
  if (VERBOSE) {
    print(paste0(" -- Higher order lookup, got ", r$num.match, " match(es)"))
  }

  if (r$num.match > topr) {
    resp.curr <- r$dt.match[1:topr]
    return(list(topr=0, resp=resp.curr))
  } else if (r$num.match > 0) {
    resp.curr <- r$dt.match[1:r$num.match]
  } else {
    resp.curr <- NULL
  }
  return(list(topr=topr - r$num.match, resp=resp.curr))
}

predict.Ngrams <- function(lastw, dt, dt.lo, topr, top=5, prev.resp, lambda=0.4, VERBOSE=T) {
  r <- lookup(lastw, dt)
  if (VERBOSE) {
    print(paste0(" -- NGrams ", length(strsplit(lastw, " ")[[1]]) + 1,
                 "-order lookup, got ", r$num.match, " match(es) - topr is: ", topr))
  }

  if (r$num.match > topr) {
    if (!is.null(prev.resp)) {
      resp.curr <- r$dt.match[1:(topr + prev.resp[, .N])] # take topr + at least size of what is already found
      # exclude previous ngrams from the low order current one
      resp.curr <- resp.curr[!(proposal %in% prev.resp[,proposal])]
    } else {
      resp.curr <- r$dt.match
    }

    topr <- ifelse(is.null(prev.resp[, .N]),
                   topr,
                   top - prev.resp[, .N]) # actual
    resp.curr <- resp.curr[1:topr]
    resp      <- rbind(prev.resp, resp.curr)
    return(list(topr=0, resp=resp[order(-score)]))
  } else if (r$num.match > 0) {
    # not enough candidate
    if (!is.null(prev.resp)) {
      resp.curr <- r$dt.match[!(proposal %in% prev.resp[, proposal])]
      r$num.match <- resp.curr[, .N]
      resp.curr <- rbind(prev.resp, resp.curr)
    } else {
      resp.curr <- r$dt.match[1:r$num.match]
    }
  } else {
    resp.curr <- NULL
  }
  topr <- topr - r$num.match
  return(list(topr=topr, resp=resp.curr))
}

predict.1grams <- function(dt, topr, prev.resp, lambda=0.4*0.4, VERBOSE=T) {
  dt.match <- dt[order(-score)][1:topr]   # attr: ngram, score
  if (!is.null(prev.resp)) {
    resp.curr <- dt.match[!(ngram %in% prev.resp[, proposal])]
  } else {
    resp.curr <- dt.match
  }
  resp.curr <- resp.curr[, c("proposal", "ngram"):=list(ngram, NULL)]  # renaming: ngram -> proposql
  resp.curr <- resp.curr[order(-score)][1:topr]
  if (is.null(prev.resp)) {
    resp <- resp.curr
  } else {
    resp <- rbind(prev.resp[, .(proposal, score)], resp.curr)
  }
  return(list(topr=0, resp=resp[order(-score)]))
}

predict.nextWord <- function(input, dts, top=5, lambda=0.4, VERBOSE=T) {
  lst    <- sanInput(input)
  # interested in the four last word only
  input  <- lst[[1]] # sanitized input (4-gram)
  vinput <- tail(lst[[2]], 4) # vector of words

  if (VERBOSE) {
    print(paste0("   input: ", input))
    print(paste0("  vinput: ", vinput))
  }

  #  5grams
  ix <- 4
  res5 <- predict.NgramHO(lastw(vinput, ix), dts$dt.5grams, dts$dt.4grams, topr=top, VERBOSE=VERBOSE)

  if (res5$topr == 0) {
    if (VERBOSE) { print(" ==> 5-grams results") }
    return(res5$resp)
  } else {
    # 4-grams lookup
    ix <- ix - 1
    res4 <- predict.Ngrams(lastw(vinput, ix), dts$dt.4grams, dts$dt.3grams,
                           topr=res5$topr, top=top, res5$resp, lambda=lambda, VERBOSE=VERBOSE)
  }

  if (res4$topr == 0) {
    if (VERBOSE) { print(" ==> 4-grams results") }
    return(res4$resp)
  } else {
    # 3-grams lookup
    ix <- ix - 1
    res3 <- predict.Ngrams(lastw(vinput, ix), dts$dt.3grams, dts$dt.2grams,
                           topr=res4$topr, top=top, res4$resp, lambda=lambda * lambda, VERBOSE=VERBOSE)
  }

  if (res3$topr == 0) {
    if (VERBOSE) { print(" ==> 3-grams results") }
    return(res3$resp)
  } else {
    # 2-grams lookup
    ix <- ix - 1
    res2 <- predict.Ngrams(lastw(vinput, 1), dts$dt.2grams, dts$dt.1grams,
                           topr=res3$topr, top=top, res3$resp, lambda=lambda * lambda * lambda, VERBOSE=VERBOSE)
  }

  if (res2$topr == 0) {
    if (VERBOSE) { print(" ==> 2-grams results") }
    return(res2$resp)
  } else {
    # 1-grams lookup
    res1 <- predict.1grams(dts$dt.1grams, topr=res2$topr, res2$resp,
                           lambda=lambda * lambda * lambda * lambda, VERBOSE=VERBOSE)
    return(res1$resp)
  }
}

wrapper.pred <- function(input, dts, top=3, benchmark=T) {
  resp  <- predict.nextWord(input, dts, top=top, VERBOSE=F)
  nresp <- resp[, .(proposal, score)][1:top]
  setcolorder(nresp, c('proposal', 'score'))
  return(nresp)
}

word.completion <- function(prefix, dts, top=3) {
  if (grepl("[^a-z\\-\\s']+", prefix, perl=T, ignore.case=T)) {
    # return early if prefix contains something else than [a-z\-'] - ignore case
    return(c())
  }
  pattern <- paste0("^", cuLc(prefix))
  r <- dts$dt.1grams[grepl(pattern, dts$dt.1grams[, ngram], perl=T)][order(-score)][, ngram][1:top]
  # r  <- dts$dt.1grams[grepl(pattern, dts$dt.1grams[, ngram], perl=T), ngram][1:top]
  return(r)
}


##
## Main, support directory (relative to YaNeWoGu dir.)
##

loadData <- function() {
  # load data for computation:
  if (!exists("dts")) {
    #
    # cat(sprintf("%s - Load model from %s...\n", tstmp(), srcPath))
    dts <- loadModel(perc=perc, model=model, srcPath=srcPath,
                     threshold=threshold, key=key)

  }
  return(dts)
}

if (!exists("perc")) { perc <- 100 } # the model to work with
model   <- paste0("model_", perc, "p_training")
srcPath <- "./data"         
if (!exists("threshold")) { threshold <- 3 }
key <- '_sbo'
# 
# dts <- loadAndStart()
#  # cat(sprintf("%s with model %s\n", tstmp(), fnameModel(model, threshold, key)))
# #
# if (! exists("inBenchmark")) {
#   for (input in c("Hello, how are you",
#                   # "Be grateful for the good times and keep the faith during the",
#                   # "Very early observations on the Bills game: Offense still struggling but the",
#                   # "Go on a romantic date at the",
#                   # "After the ice bucket challenge Louis will push his long wet hair out of his eyes with his little",
#                   # "Can you follow me please? It would mean the",
#                   # "The guy in front of me just bought a pound of bacon, a bouquet, and a case of",
#                   # "Quelque chose qui n'est pas dans le corpus",
#                   # "Et encore autre chose pour savoir",
#                   # "",
#                   # "un",
#                   # "deux mots",
#                   # "trois mots ici",
#                   "this class is ",
#                   "quatre mots a voir")) {
# 
#     print(paste0(" -- Processing input :", input))
#     resp <- wrapper.pred(input, dts, top=5, benchmark=F)
#     print(resp)
#   }
# }
