require(shiny)

source('asrt_ana_functions.R')



# Define UI
ui <- fluidPage(
  titlePanel("Dynamic Data Visualization"),
  sidebarLayout(
    sidebarPanel(
            selectInput("tasktype", "choose a task type", 
                  choices = c('motor', 'percept')),
            selectInput("unitx", "choose the x unit", 
                        choices = c('block', 'epoch')),
            
            uiOutput("dynamicUI"),  # Placeholder for dynamic UI components

    ),
    mainPanel(
      plotOutput("dataPlot")
    )
  )
)

# Define server logic
server <- function(input, output) {
  d_summary <- reactive({
    #req(input$fileInput)  # Require that a file is selected
    finfo <- list_file(input$tasktype)
    fpth <- select_file(input$sid, finfo)
    print(fpth)
    d_add_cond <- add_condition_cols(fpth, input$tasktype)
    print(head(d_add_cond))
    d_add_freq <- assign_freq(d_add_cond)
    #print(head(d_add_freq))
  
    create_summ4plot(d_add_freq, input$unitx)
  })
  
  output$dataPlot <- renderPlot({
      d_summ <- d_summary()
      #print(head(d_summary()))
      finfo <- list_file(input$tasktype)
      
      asrt_plot2(input$unitx, 
                 input$tasktype, 
                 d_summ, 
                 finfo, 
                 input$sid)
    })
  
  output$dynamicUI <- renderUI({
    
    finfo <- list_file(input$tasktype)
    
    tagList(
        
        selectInput("sid", "Choose a participant:", 
              choices = finfo$sids)
    )
    
  })  
}

# Run the application 
shinyApp(ui = ui, server = server)
