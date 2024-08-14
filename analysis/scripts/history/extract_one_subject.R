require(dplyr)
require(rio)
require(purrr)
require(tidyr)
require(ggplot2)
require(trimr)
require(data.table)
require(stringr)
require(forcats)

tasktype <- 'motor'

ddir <- paste0('../data/', tasktype)
#ddir <- '../data/motor'
#fn <- 'test002_ASRT_percept_2024-07-30_21h02.34.136.csv'
#fn <- 'test002_ASRT_percept_2024-07-31_20h06.37.355.csv'
fns <- list.files(ddir)
fn <- fns[1]
sid <- prefix <- sub("_.*", "", fn)
fpath <- file.path(ddir, fn)
d <- import(fpath)

# Assuming d2 is already converted to a data.table, if not, convert it
setDT(d)

# Create a new column that concatenates the values of three consecutive 'correct_answer_index' values
d[, triplet := paste(
  shift(correct_answer_index, n = 2, type = "lag", fill = NA),  
  shift(correct_answer_index, n = 1, type = "lag", fill = NA),
  correct_answer_index, 
    sep = "")]
#tmp <- d%>% select(correct_answer_index, triplet)
# Optional: Convert back to a DataFrame if you prefer using dplyr for subsequent operations
setDF(d)

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
  mutate(seqID = epoch, seqID2 = blockID2)

d5_summary <- d5 %>%
  group_by(block_type, seqID, trial_type, frequency_category, triplet) %>%
  reframe(rt = median(rt), 
          n = n()) %>%
  mutate(block_type = fct_relevel(block_type, "random", "practice", "learning", "testing")) %>%
  ungroup() %>%
  group_by(block_type, seqID, trial_type, frequency_category) %>%
  reframe(rt = median(rt,na.rm=T), n=sum(n))



# Plotting rt grouped by block_type, blockID, trial_type, and frequency_category

ggplot(d5_summary, aes(x = factor(seqID), y = rt, 
                       group = interaction(trial_type, frequency_category), 
                       color = frequency_category, 
                       shape = trial_type,
                       linetype = trial_type)) +
  geom_line() +  # Add lines to connect points
  geom_point() +  # Add points to mark each data entry
  facet_grid(. ~ block_type, scales = "free_x") +  # Create separate panels for each block_type
  labs(
    title = paste(tasktype, sid, sep="-"),
    x = "epoch",
    y = "Reaction Time (ms)",
    color = "Trial Type",
    linetype = "Frequency Category"
  ) +
  theme_minimal(base_size = 14) +  # Use a minimal theme for the plot
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1))  # Adjust text angle for x-axis labels for clarity

figpath <- paste0('figures/',str_replace(fn, '.csv', '_epoch.jpg'))
ggsave(figpath, width = 20, height = 15, units = "cm")



d5_summary2 <- d5 %>%
  group_by(block_type, seqID2, trial_type, frequency_category, triplet) %>%
  reframe(rt = median(rt), 
          n = n()) %>%
  mutate(block_type = fct_relevel(block_type, "random", "practice", "learning", "testing")) %>%
  ungroup() %>%
  group_by(block_type, seqID2, trial_type, frequency_category) %>%
  reframe(rt = mean(rt), n=sum(n))



# Plotting rt grouped by block_type, blockID, trial_type, and frequency_category

ggplot(d5_summary2, aes(x = factor(seqID2), y = rt, 
                       group = interaction(trial_type, frequency_category), 
                       color = frequency_category, 
                       shape = trial_type,
                       linetype = trial_type)) +
  geom_line() +  # Add lines to connect points
  geom_point() +  # Add points to mark each data entry
  facet_grid(. ~ block_type, scales = "free_x", space = 'free_x') +  # Create separate panels for each block_type
  labs(
    title = paste(tasktype, sid, sep="-"),
    x = "block",
    y = "Reaction Time (ms)",
    color = "Trial Type",
    linetype = "Frequency Category"
  ) +
  theme_minimal(base_size = 20) +  # Use a minimal theme for the plot
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1),# Adjust text angle for x-axis labels for clarity
    strip.text = element_blank(),  # Remove facet titles
    strip.background = element_blank()  # Remove facet background
    )

figpath <- paste0('figures/',str_replace(fn, '.csv', '_block.jpg'))
ggsave(figpath, width = 40, height = 15, units = "cm")

tmp <- d3 %>% 
  ungroup() %>%
  select(trial_type, 
         correct_answer_direction) %>%
  filter(trial_type=='regular') %>%
  slice(1:4)

respseq <- tmp$correct_answer_direction


tmp2 <- d %>% 
  filter(!is.na(seq_report_key.keys)) %>%
  select(starts_with('seq_report'), 
         starts_with('trials.this'))

reportseq <- tmp2 %>%
 select(trials.thisRepN, seq_report_key.keys) %>%
  group_by(trials.thisRepN) %>%
  mutate(blockID = row_number()) %>%
  ungroup()


pattern <- paste(respseq, collapse="")

# Function to count both complete and partial matches
count_partial_complete_pattern <- function(keys, pattern) {
  # Convert the keys to a string
  keys_str <- paste(keys, collapse = "")
  
  # Initialize counts for partial and complete matches
  partial_count <- 0
  complete_count <- 0
  pattern_length <- nchar(pattern)
  
  # Use a sliding window approach to check for the pattern
  for (i in 1:(nchar(keys_str) - pattern_length + 1)) {
    substring <- substr(keys_str, i, i + pattern_length - 1)
    
    # Check for complete match
    if (substring == pattern) {
      complete_count <- complete_count + 1
    }
    
    # Check for partial matches
    for (j in 1:pattern_length) {
      partial_pattern <- substr(pattern, 1, j)
      if (str_detect(substring, paste0("^", partial_pattern))) {
        partial_count <- partial_count + 1
      }
    }
  }
  
  return(list(complete_count = complete_count, partial_count = partial_count))
}

# Apply the function to each blockID and create a new data frame for the results
result <- reportseq %>%
  group_by(blockID) %>%
  do(data.frame(count_partial_complete_pattern(.$seq_report_key.keys, pattern))) %>%
  ungroup()

# Print the result
print(result)
