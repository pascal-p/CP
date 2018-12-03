#
# serverHlpr.R helper functions
#

.li <- function(l=list()) {
  s <- paste0(l, collapse=' ')
  paste0("<li>", s, "</li>")
}

.i <- function(l=list()) {
  s <- paste0(l, collapse=' ')
  paste0("<i>", s, "</i>")
}

.p <- function(l=list()) {
  s <- paste0(l, collapse=' ')
  paste0("<p>", s, "</p>")
}

.b <- function(l=list()) {
  s <- paste0(l, collapse=' ')
  paste0("<b>", s, "</b>")
}

dataModelExtract <- function(dts, sample_len=10) {
  # get a pseudo-random sample (based on smallest data.table in size)
  # min == 58316 (from dts$dt.1grams)
  if (class(dts) == "numeric") { return(NULL) }
  
  offset <- round(runif(1, 10000, 25000), 0)
    
  ndt <- dts$dt.5grams[, c('ngram'):=list(5)][offset:(offset + sample_len)]
  ndt <- rbind(ndt, dts$dt.4grams[, c('ngram'):=list(4)][offset:(offset + sample_len)])
  ndt <- rbind(ndt, dts$dt.3grams[, c('ngram'):=list(3)][offset:(offset + sample_len)])
  ndt <- rbind(ndt, dts$dt.2grams[, c('ngram'):=list(2)][offset:(offset + sample_len)])
  
  ndt1 <- dts$dt.1grams[offset:(offset + sample_len)]
  ndt1[, c('lower_ngram', 'proposal', 'score'):=list(c(''), ngram, score)]
  ndt1[, c('ngram'):=NULL]
  ndt1[, c('ngram'):=list(1)]  
  setcolorder(ndt1, c('lower_ngram', 'proposal', 'score', 'ngram'))
  ndt <- rbind(ndt, ndt1, fill=T)
  return(ndt)
}

aboutHlpr <- function() {
  paste0("<h3>Yet Another Next Word Guesser [<b>やねをぐ</b>]</h3>",
         "<h4>Short usage:</h4>",
      "<br />",
      "<div><ul>",
      .li("Click load button to load the data model, <i>this requires a few seconds</i>"),
      .li("Select prediction option (default yes)"),
      .li("Select how many words should be predicted"),
      .li("Enter a few words (the start of a sentence) in the text input box, this will trigger the prediction"),
      .li("Optionally, click to select one prediction among the proposed ones (if satisfactory)."),
      .li("Et voilà!"),
      "</ul><div><br />",

      "<h4>Notes:</h4>",
      "<div>",
      .p("This application uses <i>the simple (aka <quote>stupid</quote>) backoff algorithm</i>"),
      .p("The corpora was provided by <st>SwiftKey</st> and is composed of three main sources: "),
      "<div><ul>",
      .li("blogs, news and twitter"),
      "</div></ul>",
      .p("A sample of 80% of this corpora is used for this application (after a clean up phase)."),
      .p("Once the model is loaded, and some words are type in the input text area, an extract of the data model can be displayed in 'Data Model' tab."),
      "</div><br />",
      
      "<h4>Todo:</h4>",
      .p(list("There is a lot of room for improvment! namely: ")),
      "<ul>",
      .li("Add other algorithms, like <i>Modified Kneser-Ney Smoothing</i>,"),
      .li("<quote>Learn from input</quote> and update the data model"),
      .li("..."),
      "</ul>",
      "</div><br />",

      "<div style='display:block;float:right;width:50%;margin-left:20px;'>",
      "Pascal, November 2018 ", .i('(Corto Inc)'), 
      "</div>"
  )
}
