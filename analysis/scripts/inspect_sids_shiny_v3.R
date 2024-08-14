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
      fluidRow(
        column(8, plotOutput("rtPlot", height = "300px")),
        column(4, plotOutput("reportPlot", height = "300px"))
      ),
      fluidRow(
        column(6, plotOutput("accPlot", height = "300px")),
        column(6, plotOutput("learningPlot", height = "300px"))
        
      )
        )
  )
)

# Define server logic
server <- function(input, output) {
  d <- reactive({
    
    #req(input$fileInput)  # Require that a file is selected
    finfo <- list_file(input$tasktype)
    fpth <- select_file(input$sid, finfo)
    import_d(fpth, input$tasktype)
    
    
  })  
  
  d_add_cond <- reactive({
    add_condition_cols(d(), input$tasktype)
  })
  
  d_summary <- reactive({

    d_add_freq <- assign_freq(d_add_cond())
    create_summ4plot(d_add_freq, input$unitx)
  })
  
 
  seqreport <- reactive({
    
    report <- extr_stiseq_respseq(d(), d_add_cond()) #extract sti and response sequence
    dfresp <- report$reportseq
    stiseq <- report$stiseq
    # Example usage with dfresp dataframe
    dfresp %>%
      group_by(blockID) %>%
      summarise(
        rotation_info = list(max_repeated_rotation_in_respseq(stiseq, seq_report_key.keys))
      ) %>%
      mutate(
        max_match_count = map_int(rotation_info, "max_match_count"),
        best_rotation = map(rotation_info, "best_rotation"),
        element_match_count = map_int(rotation_info, "element_match_count")
      ) %>%
      select(-rotation_info)
  })
  
  
  output$dynamicUI <- renderUI({
    
    finfo <- list_file(input$tasktype)
    
    tagList(
      
      selectInput("sid", "Choose a participant:", 
                  choices = finfo$sids)
    )
    
  })
  
  
  output$rtPlot <- renderPlot({
      d_summ <- d_summary()
      finfo <- list_file(input$tasktype)
      
      asrt_plot(input$unitx, 
                 input$tasktype, 
                 d_summ, 
                 finfo, 
                 input$sid, 
                T, 12)
    })
  output$accPlot <- renderPlot({
    d_summ <- d_summary()
    finfo <- list_file(input$tasktype)
    asrt_acc_plot(input$unitx, 
                input$tasktype, 
                d_summ, 
                finfo, 
                input$sid, F, 10)
  })
  output$learningPlot <- renderPlot({
    
    finfo <- list_file(input$tasktype)
    
    learning_res <- compute_learning_metrics(d_summary())
    
    plot_combined_learning_metrics(learning_res, 
                                   finfo, input$sid, input$tasktype,
                                   unitx = input$unitx, 
                                   fontsize = 12, show_legend = TRUE, 
                                   legend_text_size = 10)
    
  }) 
  output$reportPlot <- renderPlot({
    finfo <- list_file(input$tasktype)
    plot_element_match_count(seqreport(), finfo,input$sid,input$tasktype)
    
    
  })  
  
 
}

# Run the application 
shinyApp(ui = ui, server = server)
