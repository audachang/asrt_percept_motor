import numpy as np
import itertools
from collections import Counter
import random

# Generate all possible combinations of length 4 using digits 0, 1, 2, 3
combinations = list(itertools.product([0, 1, 2, 3], repeat=4))

# Convert the list of combinations to a numpy array
combinations_array = np.array(combinations)

# Predefined sequence to be interleaved at even positions
predefined_sequence = [3, 0, 2, 1]

# Initialize an array to store the interleaved sequences
interleaved_sequences = []

# Interleave each combination with the predefined sequence
for combo in combinations_array:
    interleaved_sequence = [None] * 8
    interleaved_sequence[0::2] = predefined_sequence  # Fill even indices
    interleaved_sequence[1::2] = combo                # Fill odd indices
    interleaved_sequences.append(interleaved_sequence)

# Convert the list of interleaved sequences to a numpy array
interleaved_array = np.array(interleaved_sequences)

# Function to compute triplet frequencies and categorize them
def compute_triplet_frequencies_and_categorize(sequence):
    regular_triplets = []
    random_triplets = []

    for i in range(len(sequence) - 2):
        triplet = tuple(sequence[i:i+3])
        if i % 2 == 0:
            regular_triplets.append(triplet)
        else:
            random_triplets.append(triplet)

    regular_triplet_counter = Counter(regular_triplets)
    random_triplet_counter = Counter(random_triplets)

    regular_triplets_set = set(regular_triplet_counter.keys())
    random_high_triplet_counter = Counter()
    random_low_triplet_counter = Counter()

    for triplet, count in random_triplet_counter.items():
        if triplet in regular_triplets_set:
            random_high_triplet_counter[triplet] = count
        else:
            random_low_triplet_counter[triplet] = count

    total_triplets_counter = regular_triplet_counter + random_triplet_counter

    return regular_triplet_counter, random_high_triplet_counter, random_low_triplet_counter, total_triplets_counter

# Iterative sampling and export
results = []

for _ in range(10000):  # Sample up to 10000 times for iterative search
    sampled_sequences = random.sample(list(interleaved_array), 10)
    concatenated_sequence = list(itertools.chain.from_iterable(sampled_sequences))
    if len(concatenated_sequence) != 80:
        continue  # Ensure we have a concatenated sequence of length 80
    
    regular_counter, random_high_counter, random_low_counter, total_triplets_counter = compute_triplet_frequencies_and_categorize(concatenated_sequence)
    
    regular_total = sum(regular_counter.values())
    random_high_total = sum(random_high_counter.values())
    random_low_total = sum(random_low_counter.values())
    overall_total = sum(total_triplets_counter.values())
    
    regular_proportion = regular_total / overall_total
    random_high_proportion = random_high_total / overall_total
    random_low_proportion = random_low_total / overall_total
    
    results.append((concatenated_sequence, regular_counter, random_high_counter, random_low_counter, total_triplets_counter, regular_total, random_high_total, random_low_total, regular_proportion, random_high_proportion, random_low_proportion))

# Find the closest sequence to the criterion
closest_result = min(results, key=lambda x: np.abs(x[9] - 0.125))

# Print the closest result
(concatenated_sequence, regular_counter, random_high_counter, random_low_counter, total_triplets_counter, regular_total, random_high_total, random_low_total, regular_proportion, random_high_proportion, random_low_proportion) = closest_result

print("Closest Sample:")
print(f"Total Regular Frequency: {regular_total} ({regular_proportion:.3f})")
print(f"Total Random-High Frequency: {random_high_total} ({random_high_proportion:.3f})")
print(f"Total Random-Low Frequency: {random_low_total} ({random_low_proportion:.3f})")
print("Regular Triplet Frequencies:")
for triplet, frequency in regular_counter.items():
    proportion = frequency / overall_total
    print(f"{triplet}: {frequency} ({proportion:.3f})")
print("\nRandom-High Triplet Frequencies:")
for triplet, frequency in random_high_counter.items():
    proportion = frequency / overall_total
    print(f"{triplet}: {frequency} ({proportion:.3f})")
print("\nRandom-Low Triplet Frequencies:")
for triplet, frequency in random_low_counter.items():
    proportion = frequency / overall_total
    print(f"{triplet}: {frequency} ({proportion:.3f})")
print("\nConcatenated Sequence:")
print(concatenated_sequence)
print("\n" + "="*40 + "\n")
