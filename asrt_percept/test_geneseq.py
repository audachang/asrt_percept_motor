import numpy as np
import pandas as pd

# Experiment setup: gather participant ID and learning condition type
#participant_id = expInfo['participant']
participant_id = 'test'
#learning_condition_id = expInfo['learning_type']

# Define experiment parameters
repetitions_per_block = 10
number_of_learning_blocks = 20
number_of_practice_blocks = 5
number_of_motortesting_blocks = 5
number_of_percepttesting_blocks = 5
answers_str = np.array(['4', '3', '2', '1'])


## perceptual
#answers_str[pattern_seq] is the original mapping of responses to sti sequence
#i.e., 1, 4, 2, 3 or left, up, down, right
pattern_seq = [3, 0, 2, 1] 

#after 90 deg cw rotation up, right, left, down
#answers_str[pattern_seq_cw90] is the cw90 mapping of response to sti sequence
pattern_seq_cw90 = [0, 1, 3, 2]


# Lists to store filenames of generated sequence files
learning_sequence_files = []
practice_sequence_files = []
motortesting_sequence_files = []
percepttesting_sequence_files = []
# Generate learning sequences
for block_index in range(number_of_learning_blocks):
    
    # Generate an initial random sequence for the first 5 trials
    initial_random_trials = np.random.randint(0, 4, 5)
    
    # Create ordered and random sequences of patterns, then interleave them
    ordered_pattern_sequence = np.tile(pattern_seq, repetitions_per_block)
    shuffled_pattern_sequence = ordered_pattern_sequence.copy()
    np.random.shuffle(shuffled_pattern_sequence)

    # Interleave the ordered and shuffled sequences, prepend the initial random trials
    learning_sequence = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=int)
    learning_sequence[:len(initial_random_trials)] = initial_random_trials
    learning_sequence[len(initial_random_trials)::2] = ordered_pattern_sequence
    learning_sequence[len(initial_random_trials)+1::2] = shuffled_pattern_sequence
    
    # Create arrow head color seq
    arrow_col = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=object)
    arrow_col[:len(initial_random_trials)] = ["red"] * len(initial_random_trials)
    arrow_col[len(initial_random_trials)::2] = ["white"] * len(ordered_pattern_sequence)
    arrow_col[len(initial_random_trials)+1::2] = ["red"] * len(shuffled_pattern_sequence)
    # Map sequence indices to answer directions
    learning_sequence_cw90 = [pattern_seq_cw90[pattern_seq.index(elem)] for elem in learning_sequence]
    learning_sequence_answers_str = answers_str[learning_sequence_cw90]


    # Save the learning sequence to a CSV file
    learning_sequence_df = pd.DataFrame({
        'orientation_degrees': learning_sequence * 90,
        'orientation_index': learning_sequence,
        'correct_answer_index': learning_sequence_cw90,
        'correct_answer_direction': learning_sequence_answers_str,
        'arrow_color':arrow_col
    })
    learning_filename = f'sequences/{participant_id}_learning_sequence_{block_index:02}.csv'
    learning_sequence_df.to_csv(learning_filename, index=False)
    learning_sequence_files.append(learning_filename)

# Save filenames of learning sequences to an Excel file
df_learning_files = pd.DataFrame({'learning_seq_files': learning_sequence_files})
df_learning_files.to_excel(f'sequences/learning_sequence_file_list.xlsx', index=False)

# Generate practice sequences
basic_orientation_indices = [0, 1, 2, 3]  # Basic orientations

practice_sequence = np.tile(basic_orientation_indices, 21)
practice_sequence = np.append(practice_sequence, np.random.randint(0, 4))  # Ensure 85 trials in total

for block_index in range(number_of_practice_blocks):
    np.random.shuffle(practice_sequence)
    practice_sequence_cw90 = [pattern_seq_cw90[pattern_seq.index(elem)] for elem in practice_sequence]
    practice_sequence_answers_str = answers_str[practice_sequence_cw90]
    
    # Save the practice sequence to a CSV file
    practice_sequence_df = pd.DataFrame({
        'orientation_degrees': practice_sequence * 90,
        'orientation_index': practice_sequence,
        'correct_answer_index': practice_sequence_cw90,
        'correct_answer_direction': practice_sequence_answers_str, 
        'arrow_color':['red'] * len(practice_sequence)
    })    
    practice_filename = f'sequences/{participant_id}_practice_sequence_{block_index:02}.csv'
    practice_sequence_df.to_csv(practice_filename, index=False)
    practice_sequence_files.append(practice_filename)

# Save filenames of practice sequences to an Excel file
df_practice_files = pd.DataFrame({'practice_seq_files': practice_sequence_files})
df_practice_files.to_excel(f'sequences/practice_sequence_file_list.xlsx', index=False)

# Generate and save an initial random block of 85 trials
initial_random_sequence = np.random.randint(0, 4, 85)
initial_random_answers_directions = answers_str[initial_random_sequence]
initial_random_sequence_df = pd.DataFrame({
    'orientation_index': initial_random_sequence,
    'orientation_degrees': initial_random_sequence * 90,
    'correct_answer_index': initial_random_sequence,
    'correct_answer_direction': initial_random_answers_directions,
    'arrow_color': ["red"] * 85
})
# Convert correct_answer_direction to string
initial_random_sequence_df.to_csv(f'sequences/{participant_id}_initial_random.csv', index=False)

# Save the filename of the initial random sequence to an Excel file
df_initial_random_files = pd.DataFrame({'initial_random_seq_files': [f'sequences/{participant_id}_initial_random.csv']})
df_initial_random_files.to_excel('sequences/init_random_sequence_file_list.xlsx', index=True)

# Generate motor testing sequences
for block_index in range(number_of_motortesting_blocks):
    
    # Generate an initial random sequence for the first 5 trials
    initial_random_trials = np.random.randint(0, 4, 5)
    
    # Create ordered and random sequences of patterns, then interleave them
    ordered_pattern_sequence = np.tile(pattern_seq_cw90, repetitions_per_block)
    shuffled_pattern_sequence = ordered_pattern_sequence.copy()
    np.random.shuffle(shuffled_pattern_sequence)

    # Interleave the ordered and shuffled sequences, prepend the initial random trials
    motortesting_sequence = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=int)
    motortesting_sequence[:len(initial_random_trials)] = initial_random_trials
    motortesting_sequence[len(initial_random_trials)::2] = ordered_pattern_sequence
    motortesting_sequence[len(initial_random_trials)+1::2] = shuffled_pattern_sequence

    # Map sequence indices to answer directions
    motortesting_sequence_answers = motortesting_sequence
    motortesting_sequence_answers_str = answers_str[motortesting_sequence]
    
    # Create arrow head color seq
    arrow_col = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=object)
    arrow_col[:len(initial_random_trials)] = ["red"] * len(initial_random_trials)
    arrow_col[len(initial_random_trials)::2] = ["white"] * len(ordered_pattern_sequence)
    arrow_col[len(initial_random_trials)+1::2] = ["red"] * len(shuffled_pattern_sequence)


    # Save the testing sequence to a CSV file
    motortesting_sequence_df = pd.DataFrame({
        'orientation_degrees': motortesting_sequence * 90,
        'orientation_index': motortesting_sequence,
        'correct_answer_index': motortesting_sequence_answers,
        'correct_answer_direction': motortesting_sequence_answers_str, 
        'arrow_color': arrow_col
    })
    motortesting_filename = f'sequences/{participant_id}_motortesting_sequence_{block_index:02}.csv'
    motortesting_sequence_df.to_csv(motortesting_filename, index=False)
    motortesting_sequence_files.append(motortesting_filename)

# Save filenames of testing sequences to an Excel file
df_motortesting_files = pd.DataFrame({'motor_testing_seq_files': motortesting_sequence_files})
df_motortesting_files.to_excel(f'sequences/motor_testing_sequence_file_list.xlsx', index=False)

# Generate perceptual testing sequences
for block_index in range(number_of_percepttesting_blocks):
   
    # Generate an initial random sequence for the first 5 trials
    initial_random_trials = np.random.randint(0, 4, 5)
    
    # Create ordered and random sequences of patterns, then interleave them
    ordered_pattern_sequence = np.tile(pattern_seq, repetitions_per_block)
    shuffled_pattern_sequence = ordered_pattern_sequence.copy()
    np.random.shuffle(shuffled_pattern_sequence)

    # Interleave the ordered and shuffled sequences, prepend the initial random trials
    percepttesting_sequence = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=int)
    percepttesting_sequence[:len(initial_random_trials)] = initial_random_trials
    percepttesting_sequence[len(initial_random_trials)::2] = ordered_pattern_sequence
    percepttesting_sequence[len(initial_random_trials)+1::2] = shuffled_pattern_sequence
    # Create arrow head color seq
    arrow_col = np.empty(len(ordered_pattern_sequence) + len(shuffled_pattern_sequence) + len(initial_random_trials), dtype=object)
    arrow_col[:len(initial_random_trials)] = ["red"] * len(initial_random_trials)
    arrow_col[len(initial_random_trials)::2] = ["white"] * len(ordered_pattern_sequence)
    arrow_col[len(initial_random_trials)+1::2] = ["red"] * len(shuffled_pattern_sequence)

    # Map sequence indices to answer directions
    percepttesting_sequence_answers = percepttesting_sequence
    percepttesting_sequence_answers_str = answers_str[percepttesting_sequence]

    # Save the testing sequence to a CSV file
    percepttesting_sequence_df = pd.DataFrame({
        'orientation_degrees': percepttesting_sequence * 90,
        'orientation_index': percepttesting_sequence,
        'correct_answer_index': percepttesting_sequence_answers,
        'correct_answer_direction': percepttesting_sequence_answers_str, 
        'arrow_color': arrow_col
    })
    percepttesting_filename = f'sequences/{participant_id}_percepttesting_sequence_{block_index:02}.csv'
    percepttesting_sequence_df.to_csv(percepttesting_filename, index=False)
    percepttesting_sequence_files.append(percepttesting_filename)

# Save filenames of testing sequences to an Excel file
df_percepttesting_files = pd.DataFrame({'percept_testing_seq_files': percepttesting_sequence_files})
df_percepttesting_files.to_excel(f'sequences/percept_testing_sequence_file_list.xlsx', index=False)