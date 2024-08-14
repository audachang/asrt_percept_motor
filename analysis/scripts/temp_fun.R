require(dplyr)
require(rio)
require(purrr)
require(tidyr)
require(ggplot2)
require(trimr)
require(data.table)
require(stringr)
require(forcats)


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

# Function to find the rotation of a with the highest count in b
max_count_rotation_in_respseq <- function(stiseq, respseq) {
  rotations <- generate_rotations(stiseq)
  counts <- sapply(rotations, count_rotation_in_respseq, respseq = respseq)
  max_count <- max(counts)
  best_rotation <- rotations[[which.max(counts)]]
  return(list(max_count = max_count, best_rotation = best_rotation))
}

# Function to find the rotation of a with the highest count in b for each blockID
# Function to find the rotation of stiseq with the highest count in seq_report_key.keys for each blockID
max_count_rotation_in_respseq_by_block <- function(stiseq, dfresp) {
  # Group b by blockID
  b_grouped <- dfresp %>%
    group_by(blockID) %>%
    group_map(~ {
      # Extract the seq_report_key.keys column for the current blockID group
      seq_keys <- .x$seq_report_key.keys
      
      # Generate all rotations of stiseq
      rotations <- generate_rotations(stiseq)
      
      # Count the occurrence of each rotation in the seq_report_key.keys column
      counts <- sapply(rotations, function(rotation) {
        sum(sapply(1:(length(seq_keys) - length(rotation) + 1), function(i) {
          all(rotation == seq_keys[i:(i + length(rotation) - 1)])
        }))
      })
      
      # Find the maximum count and the corresponding best rotation
      max_count <- max(counts)
      best_rotation <- rotations[[which.max(counts)]]
      
      return(list(blockID = unique(.x$blockID), max_count = max_count, best_rotation = best_rotation))
    }, .keep = TRUE)
  
  # Combine results into a data frame or tibble
  results <- bind_rows(b_grouped)
  
  return(results)
}



