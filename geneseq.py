import random
from collections import Counter

def generate_sequence(length=80):
    # Predefined sequence for even positions
    predefined_sequence = [0, 1, 3, 2]
    
    # Initialize the sequence with None to fill later
    sequence = [None] * length
    
    # Fill even index positions with the predefined sequence
    for i in range(0, length, 2):
        sequence[i] = predefined_sequence[(i // 2) % 4]
    
    # Fill odd index positions with random digits from 0, 1, 2, 3
    odd_positions = list(range(1, length, 2))
    random_digits = [0, 1, 2, 3] * (length // 8)  # Make sure we have enough digits to choose from
    random.shuffle(random_digits)
    
    for i in odd_positions:
        sequence[i] = random_digits.pop()
    
    # Ensure equal frequency of 0, 1, 2, 3 in odd positions for even-odd-even triplets
    even_odd_even_triplets = [(sequence[i-1], sequence[i], sequence[i+1]) for i in range(1, length - 1, 2)]
    odd_positions_even_odd_even = list(range(1, length - 1, 2))
    counts_even_odd_even = {digit: sum(1 for triplet in even_odd_even_triplets if triplet[1] == digit) for digit in range(4)}
    target_count_even_odd_even = len(odd_positions_even_odd_even) // 4
    
    for digit in range(4):
        while counts_even_odd_even[digit] > target_count_even_odd_even:
            for i in odd_positions_even_odd_even:
                if sequence[i] == digit and counts_even_odd_even[digit] > target_count_even_odd_even:
                    replacement_candidates = [d for d in range(4) if counts_even_odd_even[d] < target_count_even_odd_even]
                    if not replacement_candidates:
                        continue
                    replacement = random.choice(replacement_candidates)
                    sequence[i] = replacement
                    counts_even_odd_even[digit] -= 1
                    counts_even_odd_even[replacement] += 1
                    break
    
    # Ensure equal frequency of 0, 1, 2, 3 in odd positions for odd-even-odd triplets
    odd_even_odd_triplets = [(sequence[i-1], sequence[i], sequence[i+1]) for i in range(2, length - 2, 2)]
    odd_positions_odd_even_odd = list(range(2, length - 2, 2))
    counts_odd_even_odd = {digit: sum(1 for triplet in odd_even_odd_triplets if triplet[1] == digit) for digit in range(4)}
    target_count_odd_even_odd = len(odd_positions_odd_even_odd) // 4
    
    for digit in range(4):
        while counts_odd_even_odd[digit] > target_count_odd_even_odd:
            for i in odd_positions_odd_even_odd:
                if sequence[i] == digit and counts_odd_even_odd[digit] > target_count_odd_even_odd:
                    replacement_candidates = [d for d in range(4) if counts_odd_even_odd[d] < target_count_odd_even_odd]
                    if not replacement_candidates:
                        continue
                    replacement = random.choice(replacement_candidates)
                    sequence[i] = replacement
                    counts_odd_even_odd[digit] -= 1
                    counts_odd_even_odd[replacement] += 1
                    break
    
    return sequence

def triplet_frequencies(sequence):
    even_odd_even_triplets = [(sequence[i-1], sequence[i], sequence[i+1]) for i in range(1, len(sequence) - 1, 2)]
    odd_even_odd_triplets = [(sequence[i-1], sequence[i], sequence[i+1]) for i in range(2, len(sequence) - 2, 2)]
    
    even_odd_even_counter = Counter(even_odd_even_triplets)
    odd_even_odd_counter = Counter(odd_even_odd_triplets)
    
    return even_odd_even_counter, odd_even_odd_counter, even_odd_even_triplets, odd_even_odd_triplets

def mark_triplets(even_odd_even_triplets, odd_even_odd_triplets):
    even_odd_even_set = set(even_odd_even_triplets)
    marked_odd_even_odd_triplets = []
    
    for triplet in odd_even_odd_triplets:
        if triplet in even_odd_even_set:
            marked_odd_even_odd_triplets.append((triplet, "high"))
        else:
            marked_odd_even_odd_triplets.append((triplet, "low"))
    
    return marked_odd_even_odd_triplets

def print_triplet_frequencies(even_odd_even_counter, odd_even_odd_counter, marked_odd_even_odd_triplets):
    print("Even-Odd-Even Triplet Frequencies:")
    print("{:<15} {:<10}".format("Triplet", "Frequency"))
    for triplet, frequency in even_odd_even_counter.items():
        print("{:<15} {:<10}".format(str(triplet), frequency))
    
    print("\nOdd-Even-Odd Triplet Frequencies (Marked):")
    print("{:<15} {:<10} {:<5}".format("Triplet", "Frequency", "Mark"))
    high_counter = Counter()
    low_counter = Counter()
    for triplet, frequency in odd_even_odd_counter.items():
        mark = "high" if triplet in even_odd_even_counter else "low"
        print("{:<15} {:<10} {:<5}".format(str(triplet), frequency, mark))
        if mark == "high":
            high_counter[triplet] = frequency
        else:
            low_counter[triplet] = frequency

    print("\nHigh Odd-Even-Odd Triplet Frequencies:")
    print("{:<15} {:<10}".format("Triplet", "Frequency"))
    for triplet, frequency in high_counter.items():
        print("{:<15} {:<10}".format(str(triplet), frequency))

    print("\nLow Odd-Even-Odd Triplet Frequencies:")
    print("{:<15} {:<10}".format("Triplet", "Frequency"))
    for triplet, frequency in low_counter.items():
        print("{:<15} {:<10}".format(str(triplet), frequency))

    print("\nMarked Odd-Even-Odd Triplets:")
    print("{:<15} {:<5}".format("Triplet", "Mark"))
    for triplet, mark in marked_odd_even_odd_triplets:
        print("{:<15} {:<5}".format(str(triplet), mark))

def main():
    sequence = generate_sequence()
    print(sequence)
    print("Length of sequence:", len(sequence))
    
    even_odd_even_counter, odd_even_odd_counter, even_odd_even_triplets, odd_even_odd_triplets = triplet_frequencies(sequence)
    marked_odd_even_odd_triplets = mark_triplets(even_odd_even_triplets, odd_even_odd_triplets)
    print_triplet_frequencies(even_odd_even_counter, odd_even_odd_counter, marked_odd_even_odd_triplets)

if __name__ == "__main__":
    main()
