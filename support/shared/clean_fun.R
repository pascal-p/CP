
cuLc <- function(r) {
  tolower(r)
}

cuConvChar <- function(r) {
  r <- gsub("’", "'", r, perl=T)       # convert single-quote
  r <- gsub("–", "-", r, perl=T)       # convert hyphen
  r <- gsub('“|”|«|»', '"', r, perl=T) # convert double-quote
  r <- gsub('·|…|•', '.', r, perl=T)   # convert dot
  r <- gsub('…', ' ', r, perl=T)       # ... -> ' '
}

cuConvUtf8Ascii <- function(r) {
  # iconv(r, "latin1", "ASCII", sub='')
  iconv(r, "UTF-8", "ASCII", sub='')
}

cuNoHashTagOrUrl <- function(r) {
  gsub("(#[a-z]+)|(https?://[^\\s]+)", ' ', r, perl=T) 
  # replace with 1 space, instead of nothing
}

# normalize dot and split by sentence using dot?
cuNormDotAndSplit <- function(r) {
  r  <- gsub("\\.\\.\\.|\\.\\.|\\?|\\!", '.', r, perl=T)
  lr <- strsplit(r, split="\\.", perl=T) # [[1]]
  sapply(unlist(lr), trimws, simplify=T, USE.NAMES=F) # strip space
}

cuWordOnly <- function(r) {
  # remove 'numbers' like 80's
  r <- gsub("\\d+\\s*'s", ' ', r, perl=T)
  
  # eliminate non-ascii word  (number, ...)
  r <- gsub("[^a-z\\-\\s']+", '', r, perl=T)
  
  # --- or -- or -  with space around or start/end pos
  r <- gsub("^\\-|\\-\\-+|\\-$", ' ',  r, perl=T)
  
  # eliminate single and double quote around word:
  r <- gsub("\\s['\"]+([\\w\\-\\s]+)[\"']+", ' \\1', r, perl=T)
  
  # single-quote transformation:
  r <- gsub("\\s'\\s|\\s'\\s*'", ' ',     r, perl=T)
  r <- gsub("'em",               "them",  r, perl=T)
  r <- gsub("'bout",             "about", r, perl=T)
  r <- gsub("'cause",            "because", r, perl=T)
  
  # eliminate seq. <space single_quote word>
  r <- gsub("\\s'[a-z]", '', r, perl=T)
  
  # replace <single_quote space> with single space
  r <- gsub("'\\s", ' ', r, perl=T)
}

# cuProfanityFilterAlt <- function(r, vect=vprof_en$V1) {
#   s <- ""
#   for (w in strsplit(r, "\\s+", perl=T, fixed=F)[[1]]) { # get the words
#     if (! (w %in% vect)) { s <- paste(s, w) } # ignoe/remove 'offending' word
#   }
#   return(c(trimws(r))) # also trim whitespace
# }

cuProfanityFilter <- function(r, vect=vprof_en$V1) {
  for (w in strsplit(r, "\\s+", perl=T, fixed=F)[[1]]) { # get the words
    if (w %in% vect) { return(c("")) } # stop and return empty (in effect eliminating the row/sentence)
  }
  return(c(trimws(r))) # also trim whitespace
}

# normalize space and hyphen
cuNormSAH <- function(r) {
  r <- gsub('\\s+', ' ', r, perl=T) # exactly one space
  gsub("\\s\\-+\\s|^\\-|\\s\\-+|\\-+\\s|\\-$", ' ', r, perl=T) # deal with - (hyphen)
}

# What about spellcheck?
cuSpellCheck <- function(r, dict=dictionary(paste0(dicpath()[2], "/en_US"))) {
  s <- ""
  # check first
  vr <- unlist(strsplit(r, "\\s", perl=T, fixed=F))
  vb <- hunspell_check(vr, dict=dict) # whole sentence => boolean vector
  ix <- 1
  # correct if necessary
  for (b in vb) {
    if (! b) {
      vr[ix] <- hunspell_suggest(vr[ix], dict=dict)[[1]][1]  # select first suggestion!
    }
    ix <- ix + 1
  }
  return(c(paste(vr, collapse=" ")))
}

cuPost <- function(vsrc) {
  vsrc <- sapply(vsrc, function(r) { gsub("^'\\s*|\\s*'$", ' ', r, perl=T) }, 
                 simplify=T, USE.NAMES=F) # starting/ending single quote

  # whole pass over vsrc, remove empty sentence, uni-letter if not a, i    
  vsrc <- vsrc[! grepl("^\\s*$|^\\s*[b-hk-z]\\s*$", vsrc)]
  
  vsrc <- sapply(vsrc, trimws, simplify=T, USE.NAMES=F)
  return(vsrc)
}

cleanUp <- function(vsrc, funLst=c(cuConvUtf8Ascii, cuLc, cuWordOnly, 
                                   cuProfanityFilter, cuSpellCheck, cuNormSAH)) {
  for (fun in funLst) {
    vsrc <- sapply(vsrc, fun, simplify=T, USE.NAMES=F)
    if (is.list(vsrc)) { vsrc <- unlist(vsrc) }  
  }
  vsrc <- cuPost(vsrc)
  
  return(unlist(vsrc))
}

# Non english word, sentence ex.:
# no entiendo
# debe ser ilegal en espana para tener algo que hacer a las ocho y media

