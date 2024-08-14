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
count_rotation_in_b <- function(rotation, b) {
  len_a <- length(rotation)
  count <- 0
  for (i in 1:(length(b) - len_a + 1)) {
    for (j in 1:len_a) {
      sub_b <- b[i:(i + j - 1)]
      if (all(rotation[1:j] == sub_b)) {
        count <- count + 1
      }
    }
  }
  return(count)
}

# Function to find the rotation of a with the highest count in b
max_count_rotation_in_b <- function(a, b) {
  rotations <- generate_rotations(a)
  counts <- sapply(rotations, count_rotation_in_b, b = b)
  max_count <- max(counts)
  best_rotation <- rotations[[which.max(counts)]]
  return(list(max_count = max_count, best_rotation = best_rotation))
}

# Given lists
a <- c(3, 1, 2, 4)
b <- c(1, 2, 3, 4, 3, 1, 2, 4, 3, 1, 3, 4)

# Compute the rotation of a with the highest count of occurrences in b
result <- max_count_rotation_in_b(a, b)
print(paste("The maximum number of times a rotation of a (including partial appearances) appears in b:", result$max_count))
print("The rotation with the highest count is:")
print(result$best_rotation)

# Example cases without scores, but checking counts
# Case 1
b_case_1 <- c(3, 1, 2, 4, 3, 1, 2, 4, 3, 1, 2, 4)
result_case_1 <- max_count_rotation_in_b(a, b_case_1)
print(paste("Case 1: The maximum number of times a rotation of a (including partial appearances) appears in b:", result_case_1$max_count))
print("The rotation with the highest count is:")
print(result_case_1$best_rotation)

# Case 2
b_case_2 <- c(1, 2, 4, 3, 1, 2, 4, 3, 1, 2, 4, 3)
result_case_2 <- max_count_rotation_in_b(a, b_case_2)
print(paste("Case 2: The maximum number of times a rotation of a (including partial appearances) appears in b:", result_case_2$max_count))
print("The rotation with the highest count is:")
print(result_case_2$best_rotation)

# Case 3
b_case_3 <- c(1, 3, 4, 2, 1, 3, 4, 2, 1, 3, 4, 2)
result_case_3 <- max_count_rotation_in_b(a, b_case_3)
print(paste("Case 3: The maximum number of times a rotation of a (including partial appearances) appears in b:", result_case_3$max_count))
print("The rotation with the highest count is:")
print(result_case_3$best_rotation)
