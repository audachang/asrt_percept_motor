require(dplyr)
require(rio)
require(purrr)
require(tidyr)
require(ggplot2)
require(trimr)
require(data.table)
require(stringr)
require(forcats)

list_file <- function(tasktype){

  ddir <- file.path('..','data',tasktype)
  fns <- list.files(ddir, pattern = '*.csv')
  
  sids <- sub("_.*", "", fns)
  
  
  finfo <- list(dir=ddir, fns=fns, sids = sids)
  return(finfo)
}


# Function to check if the prefix matches
match_prefix <- function(prefix, file_list) {
  pattern <- paste0("^", prefix, "_")
  matches <- grep(pattern, file_list)
  return(file_list[matches])
}


select_file <- function(sidstr, finfo){
  fn <- match_prefix(sidstr, finfo$fns)
  fpath <- file.path(finfo$dir, fn)
  return(fpath)
}


import_d <- function(fpath, tasktype) {
  d <- import(fpath)
  
  setDT(d)
  
  # Create a new column that concatenates the values of three consecutive 'correct_answer_index' values
  d[, triplet := paste(
    shift(correct_answer_index, n = 2, type = "lag", fill = NA),  
    shift(correct_answer_index, n = 1, type = "lag", fill = NA),
    correct_answer_index, 
    sep = "")]
  
  setDF(d)
  return(d)
}

add_condition_cols <- function(d, tasktype) {
  #specify whether perceptual or motor ($tasktype) test is conducted
  testvar <- paste0(tasktype, '_testing_seq_files')
  
  d2 <- d %>%
    filter(!is.na(orientation_index)) %>%
    mutate(block_type = case_when(
      nzchar(initial_random_seq_files) ~ "random",
      nzchar(practice_seq_files) ~ "practice",
      nzchar(learning_seq_files) ~ "learning",
      nzchar(sym(testvar)) ~ "testing",
      TRUE ~ "unknown"  # Default case if none of the above conditions are met
    ))%>%
    mutate(blockID =  case_when(
                block_type == 'practice' ~ coalesce(!!!select(., matches("practice_blocks.thisTrialN"))),　
                block_type == 'random' ~ 0,
                TRUE ~　coalesce(!!!select(., ends_with("trials.thisTrialN")))
                ))%>%
    mutate(blockID2 = case_when(
            block_type == 'random' ~ 'R',
            block_type == 'practice' ~ sprintf('P%.2d',blockID+1),
            block_type == 'learning' ~ sprintf('L%.2d', blockID+1),
            block_type == 'testing' ~ sprintf('T%.2d',blockID+1)
          )
      )%>%
    mutate(
           trial =  case_when(
                block_type == 'practice' ~  coalesce(!!!select(., matches("practice_trials.thisTrialN"))), 
                block_type == 'random' ~  coalesce(!!!select(., matches("init_random_trials.thisTrialN"))), 
                TRUE ~ coalesce(!!!select(., ends_with("loop.thisTrialN")))
             ),
           rt = key_resp.rt*1000, 
           accuracy = key_resp.corr)%>%
    mutate(epoch = case_when(
             block_type == 'learning' ~ as.character((blockID %/% 5)+1),
             block_type == 'random' ~ 'R',
             block_type == 'practice' ~ 'P',
             block_type == 'testing' ~ 'T'
            )
           ) %>%
    select(block_type, blockID, blockID2, epoch, 
           orientation_degrees, correct_answer_direction,
           accuracy,
           trial, rt, triplet,
           starts_with('motor_testing'))%>%
    group_by(block_type, blockID) %>%
    mutate(
      trial_rank = rank(trial)- 6 # Rank trials within each blockID and block_type
    ) %>%
    filter(!is.na(rt))
  
  d3 <- d2%>%
    filter(trial_rank >= 0) %>%  # Filter out the first five trials of each blockID
    mutate(trial_type = 
             if_else(trial_rank %%2 == 0, 
                     "regular", "random")) %>%
    mutate(
      trial_type = case_when(
          block_type == 'random' ~ 'random',
          block_type == 'practice' ~ 'random',
          TRUE ~ trial_type
      )
    )
 return(d3)   
}  
  
assign_freq <- function(d3){
  # add a new column called "condition", and fill it with information from both 
  # columns that code for our factors
  #d2$condition <- paste(d2$block_type, "_", d2$trial_type, sep = "")
  
  d4 <- d3 %>% 
    ungroup()%>%
    mutate(participant = 1) %>%
    select(participant, accuracy,rt, 
           block_type, blockID, blockID2, epoch, trial_type, 
           triplet, correct_answer_direction) 
  
  # Count the frequency of each unique triplet, grouped by trial_type
  triplet_frequency <- d4 %>%
    group_by(trial_type, triplet) %>%
    summarise(count = n(), .groups = 'drop')%>%  # Count the occurrences and drop the grouping afterwards
    mutate(frequency_category = 
             case_when(#trial_type == "regular" & count >= 30 ~ "high", 
                       trial_type == "regular"  ~ "high", 
                       trial_type == "random" & count >= 20 ~ "high",
                      trial_type == "random" & count < 20 ~ "low")
           ) 
    
  triplet_frequency_summ <- triplet_frequency %>%
    group_by(trial_type) %>%
    reframe(count = mean(count),
            sdcount = sd(count, na.rm = T))
    
  
  
  # Update d3 with the frequency category information by joining on trial_type and triplet
  d5 <- d4 %>%
    left_join(triplet_frequency %>% 
                select(trial_type, triplet, frequency_category), 
              by = c("trial_type", "triplet")) %>%
    #drop_na() %>%
    #filter(rt < 1000, rt > 100, !is.na(frequency_category)) %>%
    filter(!is.na(frequency_category)) %>%
    filter(
        # Filter out rows where any digit repeats exactly 3 times consecutively (repetitions)
        !str_detect(triplet, pattern = "(\\d)\\1\\1") &
          # Filter out rows that match patterns like 121, 232, etc.(trills)
        !str_detect(triplet, pattern = "(\\d)(\\d)\\1")
    ) %>%
    mutate(unitx1 = epoch, unitx2 = blockID2)
  
  return(d5)
}

create_summ4plot <- function(d5, unitx){
    if (unitx == 'epoch') {
      d5$unitx <- d5$unitx1
    }else{
      d5$unitx <- d5$unitx2  
    }  
   d5_summary <- d5 %>%
    group_by(block_type, unitx, trial_type, frequency_category, triplet) %>%
    reframe(rt = median(rt), 
            n = n(), correctn=sum(accuracy)) %>%
    mutate(block_type = fct_relevel(block_type, "random", "practice", "learning", "testing")) %>%
    ungroup() %>%
    group_by(block_type, unitx, trial_type, frequency_category) %>%
    reframe(rt = mean(rt), n=sum(n), correctn=sum(correctn)) %>%
    mutate(acc = correctn/n)
  
  
    return(d5_summary)
  
}


#compute learning effect


compute_learning_metrics <- function(d_summary) {
  
  # Filter the data for relevant conditions
  random_high <- d_summary %>%
    filter(trial_type == "random", frequency_category == "high")
  
  regular_high <- d_summary %>%
    filter(trial_type == "regular", frequency_category == "high")
  
  random_low <- d_summary %>%
    filter(trial_type == "random", frequency_category == "low")
  
  # Compute sequence learning (random high - pattern high)
  sequence_learning <- random_high %>%
    inner_join(regular_high, by = c("block_type", "unitx"), suffix = c("_random", "_pattern")) %>%
    mutate(sequence_learning = rt_random - rt_pattern) %>%
    select(block_type, unitx, sequence_learning)%>%
    mutate(block_type = fct_relevel(block_type, "random", "practice", "learning", "testing")) %>%
    filter(!block_type %in% c("random", "practice"))
  
  # Compute statistical learning (random high - random low)
  statistical_learning <- random_high %>%
    inner_join(random_low, by = c("block_type", "unitx"), suffix = c("_high", "_low")) %>%
    mutate(statistical_learning = rt_high - rt_low) %>%
    select(block_type, unitx, statistical_learning) %>%
    mutate(block_type = fct_relevel(block_type, "random", "practice", "learning", "testing")) %>%
    filter(!block_type %in% c("random", "practice"))
  
  # Return the results as a list of tibbles
  return(list(sequence_learning = sequence_learning, 
              statistical_learning = statistical_learning))
}

# Example usage:
# result <- compute_learning_metrics(d_summary)
# result$sequence_learning  # View the sequence learning tibble
# result$statistical_learning  # View the statistical learning tibble





#plotting RT results
asrt_plot <- function(
    unitx, tasktype, 
    d_summary, finfo, 
    sidstr,
    show_legend = TRUE,  # New argument to control legend display
    legend_text_size = 12  # New argument to control legend font size
) {
  
  print(match_prefix(sidstr, finfo$fns))
  x_var <- "unitx"
  base_size <- 12
  
  if (unitx == 'epoch') {
    x_label <- "epoch"
    figpath_suffix <- "_epoch.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x")
  } else {
    x_label <- "block"
    figpath_suffix <- "_block.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x", space = "free_x")
  }
  
  fig <- ggplot(d_summary, aes_string(x = x_var, y = "rt", 
                                      group = "interaction(trial_type, frequency_category)", 
                                      color = "frequency_category", 
                                      shape = "trial_type", 
                                      linetype = "trial_type")) +
    geom_line() + 
    geom_point(size=4) + 
    do.call(facet_grid, facet_params) +
    labs(
      title = paste(tasktype, sidstr, sep = "-"),
      x = x_label,
      y = "Reaction Time (ms)",
      color = "Frequency Category",
      linetype = "Trial Type"
    ) +
    theme_minimal(base_size = base_size) +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1),
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor = element_blank(),  # Remove minor grid lines
      text = element_text(size = base_size + 4)  # Increase font size
    )
  
  # Conditionally hide the legend if show_legend is FALSE
  if (!show_legend) {
    fig <- fig + theme(legend.position = "none")
  } else {
    # Adjust legend text size if the legend is shown
    fig <- fig + theme(
      legend.text = element_text(size = legend_text_size),
      legend.title = element_text(size = legend_text_size)
    )
  }
  
  if (unitx != 'epoch') {
    fig <- fig + theme(strip.text = element_blank(), strip.background = element_blank())
  }
  
  fn <- match_prefix(sidstr,finfo$fns)
  
  figpath <- paste0('figures/', tasktype,'/', str_replace(fn, '.csv', figpath_suffix))
  print(str_replace(fn, '.csv', figpath_suffix))
  print(fig)
  ggsave(figpath, width = ifelse(unitx== 'epoch', 20, 40), height = 15, units = "cm")
  
  return(fig)
}


#plotting accuracy results
asrt_acc_plot <- function(
    unitx, tasktype, 
    d_summary, finfo, 
    sidstr,
    show_legend = TRUE,  # New argument to control legend display
    legend_text_size = 12  # New argument to control legend font size
) {
  
  print(match_prefix(sidstr, finfo$fns))
  x_var <- "unitx"
  base_size <- 12
  if (unitx == 'epoch') {
    x_label <- "epoch"
    figpath_suffix <- "_acc_epoch.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x")
  } else {
    x_label <- "block"
    figpath_suffix <- "_acc_block.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x", space = "free_x")
  }
  
  fig <- ggplot(d_summary, aes_string(x = x_var, y = "acc", 
                                      group = "interaction(trial_type, frequency_category)", 
                                      color = "frequency_category", 
                                      shape = "trial_type", 
                                      linetype = "trial_type")) +
    geom_line() + 
    geom_point(size=4) + 
    do.call(facet_grid, facet_params) +
    labs(
      title = paste(tasktype, sidstr, sep = "-"),
      x = x_label,
      y = "Accuracy",
      color = "Frequency Category",
      linetype = "Trial Type"
    ) +
    theme_minimal(base_size = base_size) +
    theme(
      
      axis.text.x = element_text(angle = 90, hjust = 1),
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor = element_blank(),  # Remove minor grid lines
      text = element_text(size = base_size + 4)  # Increase font size
      
    )
  
  # Conditionally hide the legend if show_legend is FALSE
  if (!show_legend) {
    fig <- fig + theme(legend.position = "none")
  } else {
    # Adjust legend text size if the legend is shown
    fig <- fig + theme(
      legend.text = element_text(size = legend_text_size),
      legend.title = element_text(size = legend_text_size)
    )
  }
  
  if (unitx != 'epoch') {
    fig <- fig + theme(strip.text = element_blank(), strip.background = element_blank())
  }
  
  fn <- match_prefix(sidstr,finfo$fns)
  
  figpath <- paste0('figures/', tasktype,'/', str_replace(fn, '.csv', figpath_suffix))
  print(str_replace(fn, '.csv', figpath_suffix))
  print(fig)
  ggsave(figpath, width = ifelse(unitx == 'epoch', 20, 40), height = 15, units = "cm")
  
  return(fig)
}

#plot learning metrics

plot_combined_learning_metrics <- function(
    learning_metrics, 
    finfo, sidstr, tasktype,
    unitx,  # 'epoch' or 'block'
    fontsize = 12,  # Base font size
    show_legend = TRUE,  # Flag to show/hide legend
    legend_text_size = 12  # Legend text size
) {
  
  # Extract sequence learning and statistical learning data
  sequence_learning <- learning_metrics$sequence_learning
  statistical_learning <- learning_metrics$statistical_learning
  
  # Combine the two learning metrics into a single tibble
  combined_learning <- sequence_learning %>%
    rename(learning = sequence_learning) %>%
    mutate(type = "Sequence") %>%
    bind_rows(
      statistical_learning %>%
        rename(learning = statistical_learning) %>%
        mutate(type = "Statistical")
    )
  x_var <- "unitx"
  base_size <- 12
  
  if (unitx == 'epoch') {
    x_label <- "epoch"
    figpath_suffix <- "_learning_metrics_epoch.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x")
  } else {
    x_label <- "block"
    figpath_suffix <- "_learning_metrics_block.jpg"
    facet_params <- list(. ~ block_type, scales = "free_x", space = "free_x")
  }
  
  # Plot combined learning by seqID
  fig <- ggplot(combined_learning, aes_string(x = x_var, y = "learning", 
                                              group = "interaction(type, block_type)", 
                                              color = "type")) +
    geom_line() + 
    geom_point(size = 4) + 
    do.call(facet_grid, facet_params) +
    labs(
      title = "Learning metrics",
      x = x_label,
      y = "Difference RT(ms)",
      color = "Learning Type"
    ) +
    theme_minimal(base_size = fontsize) +
    theme(
      axis.text.x = element_text(angle = 90, hjust = 1),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      text = element_text(size = fontsize + 4)  # Increase font size
    )
  
  # Conditionally hide the legend if show_legend is FALSE
  if (!show_legend) {
    fig <- fig + theme(legend.position = "none")
  } else {
    # Adjust legend text size if the legend is shown
    fig <- fig + theme(
      legend.text = element_text(size = legend_text_size),
      legend.title = element_text(size = legend_text_size)
    )
  }
  
  fn <- match_prefix(sidstr,finfo$fns)
  
  figpath <- paste0('figures/', tasktype,'/', str_replace(fn, '.csv', figpath_suffix))
  print(str_replace(fn, '.csv', figpath_suffix))
  print(fig)
  ggsave(figpath, width = ifelse(unitx == 'epoch', 20, 40), height = 15, units = "cm")
  

  return(fig)
}

# Example usage:
# learning_metrics <- compute_learning_metrics(d_summary)
#plot_combined_learning_metrics(learning_metrics, unitx = 'epoch', fontsize = 14, show_legend = TRUE, legend_text_size = 10)




# extracting the reported sequence and the presented sequence
extr_stiseq_respseq <- function(d, d_add_cond){    
  tmp <- d_add_cond %>% 
    ungroup() %>%
    select(trial_type, 
           correct_answer_direction) %>%
    filter(trial_type=='regular') %>%
    slice(1:4)
  
  stiseq <- tmp$correct_answer_direction
  
  
  tmp2 <- d %>% 
    filter(!is.na(seq_report_key.keys)) %>%
    select(starts_with('seq_report'), 
           starts_with('trials.this'))
  
  reportseq <- tmp2 %>%
    select(trials.thisRepN, seq_report_key.keys) %>%
    group_by(trials.thisRepN) %>%
    mutate(blockID = sprintf("L%.2d",row_number())) %>%
    ungroup()
  
  #report at each block
  report = list(stiseq=stiseq, reportseq=reportseq)  
  return(report)
  
}

# Function to generate all rotations of a vector
generate_rotations <- function(vec) {
  n <- length(vec)
  rotations <- list()
  for (i in 0:(n-1)) {
    rotations[[i+1]] <- c(tail(vec, n-i), head(vec, i))
  }
  return(rotations)
}

# Function to count occurrences of a specific rotation in b, considering partial appearances
count_rotation_in_respseq <- function(rotation, respseq) {
  len_a <- length(rotation)
  count <- 0
  for (i in 1:(length(respseq) - len_a + 1)) {
    for (j in 1:len_a) {
      sub_respseq <- respseq[i:(i + j - 1)]
      if (all(rotation[1:j] == sub_respseq)) {
        count <- count + 1
      }
    }
  }
  return(count)
}


# Function to count the number of correctly repeated elements for a specific rotation in respseq
# and also to count the number of elements that match the rotation pattern
count_repeated_elements_and_matches <- function(rotation, respseq) {
  match_count <- 0
  element_match_count <- 0
  len_a <- length(rotation)
  
  for (i in 1:(length(respseq) - len_a + 1)) {
    if (all(rotation == respseq[i:(i + len_a - 1)])) {
      match_count <- match_count + 1
      element_match_count <- element_match_count + len_a
    }
  }
  
  return(list(match_count = match_count, element_match_count = element_match_count))
}

# Function to find the rotation of stiseq with the most correctly repeated elements in respseq
# and also return the number of elements that match the rotation pattern
max_repeated_rotation_in_respseq <- function(stiseq, respseq) {
  rotations <- generate_rotations(stiseq)
  results <- sapply(rotations, count_repeated_elements_and_matches, respseq = respseq, simplify = FALSE)
  
  max_match_count <- max(sapply(results, function(x) x$match_count))
  best_rotation_index <- which.max(sapply(results, function(x) x$match_count))
  best_rotation <- rotations[[best_rotation_index]]
  element_match_count <- results[[best_rotation_index]]$element_match_count
  
  return(list(max_match_count = max_match_count, best_rotation = best_rotation, element_match_count = element_match_count))
}


# Function to plot element_match_count as a function of blockID
plot_element_match_count <- function(result, finfo, sidstr, tasktype) {
  
  
  fig <- ggplot(result, aes(x = factor(blockID), y = element_match_count)) +
    geom_point(size = 3, color = "blue") +  # Plot points
    geom_line(group = 1, color = "blue") +  # Connect points with a line
    geom_hline(yintercept = 10, linetype = "dashed", color = "red") +  # Add horizontal line at count = 10
    labs(x = "Learning Block", y = "Element Match Count", 
         title = "Sequence Report Accuracy per Learning Block") +  # Labels and title
    theme_minimal() +  # Clean theme
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),  # Rotate x-axis labels for clarity
      plot.title = element_text(hjust = 0.5)  # Center the plot title
    )
  
  figpath_suffix <- "_seqreport.jpg"
  fn <- match_prefix(sidstr,finfo$fns)
  
  figpath <- paste0('figures/', tasktype,'/', str_replace(fn, '.csv', figpath_suffix))
  print(str_replace(fn, '.csv', figpath_suffix))
  print(fig)
  ggsave(figpath, height = 15, units = "cm")
  
  
  
  
  
}


