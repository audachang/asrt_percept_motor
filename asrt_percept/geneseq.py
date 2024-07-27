import numpy as np
import itertools
from collections import Counter
import random

class TripletSequenceGenerator:
    def __init__(self, predefined_sequence, display_info=True):
        # Validate predefined sequence
        if not (set(predefined_sequence) == {0, 1, 2, 3} and len(predefined_sequence) == 4):
            raise ValueError("Predefined sequence must consist of 0, 1, 2, 3 and be of length 4")
        self.predefined_sequence = predefined_sequence
        self.display_info = display_info
        self.interleaved_sequences = self._generate_interleaved_sequences()

    def _generate_interleaved_sequences(self):
        # Generate all possible combinations of length 4 using digits 0, 1, 2, 3
        combinations = list(itertools.product([0, 1, 2, 3], repeat=4))
        combinations_array = np.array(combinations)

        # Initialize a list to store the interleaved sequences
        interleaved_sequences = []

        # Interleave each combination with the predefined sequence
        for combo in combinations_array:
            interleaved_sequence = [None] * 8
            interleaved_sequence[0::2] = self.predefined_sequence  # Fill even indices
            interleaved_sequence[1::2] = combo  # Fill odd indices
            interleaved_sequences.append(interleaved_sequence)

        # Convert the list of interleaved sequences to a numpy array
        return np.array(interleaved_sequences)

    def _compute_triplet_frequencies_and_categorize(self, sequence):
        # Initialize lists to store regular and random triplets
        regular_triplets = []
        random_triplets = []

        # Iterate through the sequence and categorize triplets
        for i in range(len(sequence) - 2):
            triplet = tuple(sequence[i:i+3])
            if i % 2 == 0:
                regular_triplets.append(triplet)
            else:
                random_triplets.append(triplet)

        # Count the frequency of each triplet in regular and random categories
        regular_triplet_counter = Counter(regular_triplets)
        random_triplet_counter = Counter(random_triplets)

        # Create sets and counters for random-high and random-low triplets
        regular_triplets_set = set(regular_triplet_counter.keys())
        random_high_triplet_counter = Counter()
        random_low_triplet_counter = Counter()

        # Categorize random triplets as random-high or random-low
        for triplet, count in random_triplet_counter.items():
            if triplet in regular_triplets_set:
                random_high_triplet_counter[triplet] = count
            else:
                random_low_triplet_counter[triplet] = count

        # Combine regular and random triplets to get total triplets
        total_triplets_counter = regular_triplet_counter + random_triplet_counter

        return regular_triplet_counter, random_high_triplet_counter, random_low_triplet_counter, total_triplets_counter

    def generate(self, iterations=10000):
        results = []

        # Perform iterative sampling
        for _ in range(iterations):
            # Sample 10 sequences randomly
            sampled_sequences = random.sample(list(self.interleaved_sequences), 10)
            concatenated_sequence = list(itertools.chain.from_iterable(sampled_sequences))

            # Ensure the concatenated sequence is of length 80
            if len(concatenated_sequence) != 80:
                continue

            # Compute triplet frequencies and categorize them
            regular_counter, random_high_counter, random_low_counter, total_triplets_counter = self._compute_triplet_frequencies_and_categorize(concatenated_sequence)

            # Calculate totals and proportions
            regular_total = sum(regular_counter.values())
            random_high_total = sum(random_high_counter.values())
            random_low_total = sum(random_low_counter.values())
            overall_total = sum(total_triplets_counter.values())

            regular_proportion = regular_total / overall_total
            random_high_proportion = random_high_total / overall_total
            random_low_proportion = random_low_total / overall_total

            # Store the result
            results.append((concatenated_sequence, regular_counter, random_high_counter, random_low_counter, total_triplets_counter, regular_total, random_high_total, random_low_total, regular_proportion, random_high_proportion, random_low_proportion))

        # Find the closest result to the criterion
        closest_result = min(results, key=lambda x: np.abs(x[9] - 0.125))
        self._print_and_export_result(closest_result)

    def _print_and_export_result(self, result):
        (concatenated_sequence, regular_counter, random_high_counter, random_low_counter, total_triplets_counter, regular_total, random_high_total, random_low_total, regular_proportion, random_high_proportion, random_low_proportion) = result

        if self.display_info:
            print("Closest Sample:")
            print(f"Total Regular Frequency: {regular_total} ({regular_proportion:.3f})")
            print(f"Total Random-High Frequency: {random_high_total} ({random_high_proportion:.3f})")
            print(f"Total Random-Low Frequency: {random_low_total} ({random_low_proportion:.3f})")
            print("Regular Triplet Frequencies:")
            for triplet, frequency in regular_counter.items():
                proportion = frequency / sum(total_triplets_counter.values())
                print(f"{triplet}: {frequency} ({proportion:.3f})")
            print("\nRandom-High Triplet Frequencies:")
            for triplet, frequency in random_high_counter.items():
                proportion = frequency / sum(total_triplets_counter.values())
                print(f"{triplet}: {frequency} ({proportion:.3f})")
            print("\nRandom-Low Triplet Frequencies:")
            for triplet, frequency in random_low_counter.items():
                proportion = frequency / sum(total_triplets_counter.values())
                print(f"{triplet}: {frequency} ({proportion:.3f})")
            print("\nConcatenated Sequence:")
            print(concatenated_sequence)
            print("\n" + "="*40 + "\n")

        self.final_sequence = concatenated_sequence


    def cw90(self, sequence):
        # Define the mapping rule
        mapping = {3: 0, 0: 1, 1: 2, 2: 3}
        # Apply the mapping rule to the sequence
        return np.array([mapping[digit] for digit in sequence])