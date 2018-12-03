#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)
library(shinyjs)

source("./support/shared/init_defs.R")

# Define UI for application that draws a histogram
shinyUI(fluidPage(theme = shinytheme("slate"),
                  shinyjs::useShinyjs(),
                  
  # Application title
  titlePanel("YANeWoGu"), # Yet Another Word Guesser
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(

      radioButtons(
        inputId="inp_nextword", label="- Predict next word:",
        choices=list("yes", "no"),
        selected="yes"
      ),
      
      conditionalPanel(
        condition = "input.inp_nextword == 'yes'",
        sliderInput("inp_num_words", # number of words for prediction
                    "- Number of predicted words:",
                    min=1, max=5, value=3, step=1, ticks=F)
      ),
      
      br(),
      
      hidden(
        span(id='load', actionButton("inp_load", "Load Data"))
      ),
      actionButton("inp_clear", "Clear Input")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      
      tabsetPanel(
        id="theTabs",
        
        tabPanel("Prediction",
                 h3("Predicting next word:"),
                 br(),
                 htmlOutput("out_info", inline=T),
                 br(),
                 
                 textInput(inputId="inp_sentence", label="Enter a sentence", value=INIT.SENTENCE, 
                           placeholder="Enter a sentence here...", width='90%'),
                 br(),
                 
                 ## offer selection
                 hidden(
                   span(id='for_pred', selectInput("inp_pred", "Choose a prediction:", list()))
                 ),
                 br(),
                 
                 ## next word prediction
                 uiOutput("out_label"),
                 verbatimTextOutput('out_sentence'),
                 br(),
                 
                 uiOutput("out_next_poss_words"),
                 tableOutput("out_predictions"),
                 
                 value="main"),
        
        tabPanel("Data Model",
                 h3("5-gram model (extract)"),
                 dataTableOutput("dts"),
                 value="data_model"),
        
        tabPanel("About",
                 htmlOutput("about"),
                 value="about")
      )
      
    )
  )
))
