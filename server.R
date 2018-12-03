#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
require(data.table)

# order matters
source("./support/shared/init_defs.R")
source("./support/simple_backoff_nopt.R")
source("./support/serverHlpr.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  if (!exists("val$dts")) { 
    output$out_info <- renderText(paste0("<p style='color: darkred;'>Model <b>not loaded yet</b>.<br />",
                                         "<span style='font-style: italic; color: darkred;'>Loading ",
                                         "take a few seconds and will be done once you click 'Load Data' button.</span></p>"))
    shinyjs::toggle(id="load", anim=T)
  } 
  
  # reactiveValues object for storing data model.
  val <- reactiveValues(dts = NULL)
  
  ## modal
  dataModal <- function() {
    modalDialog(
      helpText("About to load the data model.",
               "It takes a few seconds. Please proceed by clicking ok.",
               "This note will disapear once the data model is loaded."),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("inp_ok", "OK")
      )
    )
  }
  
  # Show modal when "Load Data" button is clicked.
  observeEvent(input$inp_load, {
    showModal(dataModal())
  })
  
  # When OK button is pressed, load the data model and remove the modal, disable and hide load button
  observeEvent(input$inp_ok, {
    start_time <- Sys.time()
    val$dts    <- loadData()
    end_time   <- Sys.time()
    removeModal()
    
    # Display information about selected data
    output$out_info <- renderText(paste0("<p style='color: darkslateblue;'>Model <b>loaded</b> (took ",
                                         round(end_time - start_time, 2), "s).</p>"))
    
    shinyjs::disable("inp_load")
    shinyjs::toggle(id="load", anim=T)
    
  })
  
  ## When inp_clear button is pressed, clear input text box
  observeEvent(input$inp_clear, {
    updateTextInput(session, "inp_sentence", value='')
    shinyjs::toggle(id="for_pred", anim=T)
  })
  
  ## clear initial sentence
  # observeEvent(input$inp_load, {
  #  updateTextInput(session, "inp_sentence", value='')
  # })
  
  ## reactive next word prediction (or word completion)
  react_nextword <- reactive({
    opt_pred  <- input$inp_nextword
    num_words <- input$inp_num_words
    sentence  <- input$inp_sentence

    dt_resp   <- NULL  # for datatable

    if (opt_pred == "yes" && !is.null(val$dts)) {
      len <- nchar(sentence)
      if (len > 0) {
        ## get prediction 
        dt_resp <- wrapper.pred(as.character(sentence), val$dts, top=num_words)
        
        wp <- dt_resp[, proposal]
        # populate inputbox  and make it visible (therefore selectable)
        updateSelectInput(session, "inp_pred",
                          label=paste("Select prediction (", length(wp),"): "),
                          choices=wp,
                          selected=' ' # head(wp, 1)
        )
        shinyjs::show(id="for_pred", anim=T)
      }
    }
    dt_resp
  })

  ## if we click a prediction word, then update input sentence...
  observe({
    opt_pred <- input$inp_nextword
    prefix   <- input$inp_sentence
    wp       <- input$inp_pred
    
    if (opt_pred == "yes"  && (! is.null(wp)) && (! grepl("^\\s*$", wp))) { 
      words  <- strsplit(prefix, "\\s+", perl=T)[[1]]
      prefix <- paste0(words, collapse=" ")
      updateTextInput(session, "inp_sentence", value=paste(prefix, wp, " "))
      
      updateSelectInput(session, "inp_pred",
                        label=paste0("Select prediction - click to select: "),
                        choices=NULL,
                        selected=' ')
    }
  })
  
  ## label and value (returning what was entered) - depending on react_nextword()
  output$out_label <- renderUI({
    ans <- react_nextword()
    tagList(
      if (!is.null(ans)) { h5("You entered the following sentence: ") }
    )
  })
  
  output$out_sentence <- renderText({
    ans      <- react_nextword()
    sentence <- input$inp_sentence
    
    if (!is.null(ans)) { as.character(sentence) }
  })
  
  ## prediction label and output table
  output$out_next_poss_words <- renderUI({
    numPred  <- input$inp_num_words
    nextWord <- input$inp_nextword
    ans      <- react_nextword()
    
    tagList(
      if (is.null(ans)) { NULL }
      else if (nextWord == "yes") {
        h5(paste0("Next possible ", numPred, " word", ifelse(numPred > 1, "s", ""), ":"))
      } else {
        h5("Prediction disabled")
      }
    )
  })

  output$out_predictions <- renderTable({
      if (input$inp_nextword == "yes") { react_nextword() } 
      else { NULL  }
    },
    striped=F, hover=T, bordered=T, width="250px", colnames=T, align="lr", spacing="s", digits=8
  )
 
  ## for Data Model tab - Data Model Extract
  output$dts <- renderDataTable({
    ans <- react_nextword()

    if (!is.null(ans)) { dataModelExtract(val$dts) }
  }, options=list(
    pageLength=5,
    lengthMenu=list(c(5, 10, -1), c('5', '10', 'All'))
    )
  )
  
  ## for About tab
  output$about <- renderText({aboutHlpr()})
})
