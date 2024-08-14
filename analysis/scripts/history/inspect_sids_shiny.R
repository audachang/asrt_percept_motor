require(shiny)
require(dplyr)
require(tidyr)
require(ggplot2)
require(stringr)
require(data.table)
require(rio)  # For importing data

# Define UI
ui <- fluidPage(
  titlePanel("Dynamic Data Visualization"),
  sidebarLayout(
    sidebarPanel(
            selectInput("tasktype", "choose a task type", 
                  choices = c('motor', 'percept')),
            uiOutput("dynamicUI"),  # Placeholder for dynamic UI components

    ),
    mainPanel(
      plotOutput("dataPlot")
    )
  )
)

# Define server logic
server <- function(input, output) {
  data_reactive <- reactive({
    req(input$fileInput)  # Require that a file is selected
    
    d <- import(paste0("../data/",input$tasktype,"/",input$fileInput, sep=""))
    setDT(d)
    
    # Your data processing here, summarizing into d4_summary
    d[, triplet := paste(
      shift(correct_answer_index, n = 2, type = "lag", fill = NA),  
      shift(correct_answer_index, n = 1, type = "lag", fill = NA),
      correct_answer_index, 
      sep = "")]
    setDF(d)
    d
  })
  
  output$dataPlot <- renderPlot({
    d <- data_reactive()  # Get the reactive data
    # Assuming d2 processing, d3, and d4_summary are correct
    # For simplicity, here I assume d4_summary is ready to plot,
    # Normally you would include all transformation steps here.
    d2 <- d %>%
      filter(!is.na(key_resp.rt)) %>%
      mutate(block_type = case_when(
        nzchar(initial_random_seq_files) ~ "random",
        nzchar(practice_seq_files) ~ "practice",
        nzchar(learning_seq_files) ~ "learning",
        nzchar(motor_testing_seq_files) ~ "testing",
        TRUE ~ "unknown"  # Default case if none of the above conditions are met
      )) %>%
      mutate(blockID =  coalesce(!!!select(., ends_with("trials.thisTrialN"))),
             trial =  coalesce(!!!select(., ends_with("loop.thisTrialN"))),
             rt = key_resp.rt*1000, 
             accuracy = key_resp.corr)%>%
      mutate(epoch = (blockID %/% 5) + 1) %>%
      select(block_type, blockID, epoch,
             orientation_degrees, correct_answer_index,
             accuracy,
             trial, rt, triplet) %>%
      filter(block_type != "random" & block_type != "practice", 
             block_type !="unknown") %>%  # Exclude 'random' and 'practice' block types
      group_by(block_type, blockID) %>%
      mutate(
        trial_rank = rank(trial)- 7  # Rank trials within each blockID and block_type
      ) %>%
      filter(trial_rank > 0) %>%  # Filter out the first five trials of each blockID
      mutate(trial_type = 
               if_else(trial_rank %%2 == 0, 
                       "random", "regular"))
    
    
    
    
    # add a new column called "condition", and fill it with information from both 
    # columns that code for our factors
    #d2$condition <- paste(d2$block_type, "_", d2$trial_type, sep = "")
    
    d3 <- d2 %>% 
      ungroup()%>%
      mutate(participant = 1) %>%
      select(participant, accuracy,rt, 
             block_type, blockID, epoch, trial_type, 
             triplet, correct_answer_index) 
    
    # Count the frequency of each unique triplet, grouped by trial_type
    triplet_frequency <- d3 %>%
      group_by(trial_type, triplet) %>%
      summarise(count = n(), .groups = 'drop')%>%  # Count the occurrences and drop the grouping afterwards
      mutate(frequency_category = 
               case_when(trial_type == "regular" & count >= 30 ~ "high", 
                         #trial_type == "regular" & count < 10 ~ "low", 
                         trial_type == "random" & count >= 15 ~ "high",
                         trial_type == "random" & count < 15 & count > 5  ~ "low")
      )
    
    
    
    # Update d3 with the frequency category information by joining on trial_type and triplet
    d4 <- d3 %>%
      left_join(triplet_frequency %>% 
                  select(trial_type, triplet, frequency_category), 
                by = c("trial_type", "triplet")) %>%
      drop_na() %>%
      filter(rt < 1000, rt > 100) %>%
      filter(
        # Filter out rows where any digit repeats exactly 3 times consecutively (repetitions)
        !str_detect(triplet, pattern = "(\\d)\\1\\1") &
          # Filter out rows that match patterns like 121, 232, etc.(trills)
          !str_detect(triplet, pattern = "(\\d)(\\d)\\1")
      )%>%
      mutate(seqID = factor(epoch))
    
    
    d4_summary <- d4 %>%
      group_by(block_type, seqID, 
               trial_type, frequency_category) %>%
      reframe(rt = mean(rt, na.rm=T), 
              n = n()) 
    
    # Plotting code
    ggplot(d4_summary, 
           aes(x = seqID, y = rt, 
              group = interaction(trial_type, frequency_category), 
              color = trial_type, linetype = frequency_category,
              shape = frequency_category), 
           ) +
      geom_line() +
      geom_point() +
      facet_wrap(. ~ block_type, scales = "free_x") +
      labs(
        title = input$fileInput,
        x = "Block ID",
        y = "Reaction Time (ms)",
        color = "Trial Type",
        linetype = "Frequency Category"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))

    print(file.path('figures',input$taskType,str_replace(input$fileInput, '.csv', '.jpg')))
    
    ggsave(file.path('figures',input$tasktype, str_replace(input$fileInput, '.csv', '.jpg')), 
           width = 20, height = 15, units = "cm")
    
    fig <- ggplot(d4_summary, 
           aes(x = seqID, y = rt, 
               group = interaction(trial_type, frequency_category), 
               color = trial_type, linetype = frequency_category,
               shape = frequency_category), 
    ) +
      geom_line() +
      geom_point() +
      facet_wrap(. ~ block_type, scales = "free_x") +
      labs(
        title = input$fileInput,
        x = "Block ID",
        y = "Reaction Time (ms)",
        color = "Trial Type",
        linetype = "Frequency Category"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))
    
    print(fig)
    })
  
  output$dynamicUI <- renderUI({
    tagList(
  
        selectInput("fileInput", "Choose a CSV File:", 
              choices = list.files(
                path = paste0("../data/", input$tasktype ,sep=""), 
                full.names = F, 
                pattern = "\\.csv$"))
    )
    
  })  
}

# Run the application 
shinyApp(ui = ui, server = server)
