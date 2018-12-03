
setSeed <- function(s=20181006) {
  set.seed(s)
}

withTiming <- function(fun, silent=F) {
  resTime <- system.time(res <- fun)
  if (silent) {
    return(list(resTime, res))
  } else {
    # cat(paste0(paste0(resTime), "\n"))
    print(resTime)
    return(res)
  }
}

tstmp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}
