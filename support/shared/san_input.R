source("support/shared/clean_fun.R")

# Sanitize input
sanInput <- function(input) {
  input  <- cuWordOnly(cuLc(input))
  input  <- trimws(input, which="both")
  vinput <- strsplit(input, " ")[[1]]
  vinput <- vinput[vapply(vinput,
                          function(w) { nchar(w) > 0 },
                          logical(1), USE.NAMES=F)] # eliminate empty word...
  finput <- paste0(tail(vinput, 2), collapse=" ")   # get last two words
  return(list(input, vinput, finput))
}
