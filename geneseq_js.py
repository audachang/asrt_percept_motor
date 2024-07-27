import random

def variable_creation(subject, session, is_offline, is_first_five_random):
    # Define subject number
    if not is_offline:
        subject_id = ''.join(random.choices('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', k=15))
    else:
        subject_id = subject

    # Define session number
    if not is_offline:
        session_number = 1
    else:
        session_number = session

    # Define sequence
    if not is_offline:
        used_sequence = random.sample([0, 1, 2, 3], 4)
    else:
        sequences = [
            [0, 1, 2, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3, 1], [0, 3, 1, 2], [0, 3, 2, 1],
            [1, 0, 2, 3], [1, 0, 3, 2], [1, 2, 0, 3], [1, 2, 3, 0], [1, 3, 0, 2], [1, 3, 2, 0],
            [2, 0, 1, 3], [2, 0, 3, 1], [2, 1, 0, 3], [2, 1, 3, 0], [2, 3, 0, 1], [2, 3, 1, 0],
            [3, 0, 1, 2], [3, 0, 2, 1], [3, 1, 0, 2], [3, 1, 2, 0], [3, 2, 0, 1], [3, 2, 1, 0]
        ]
        used_sequence = sequences[(int(subject_id) - 1) % 24]

    used_sequence_string = ''.join(map(str, [v + 1 for v in used_sequence]))

    if is_first_five_random:
        first_valid_trial = 7
        number_of_block_elements = 85
    else:
        first_valid_trial = 2
        number_of_block_elements = 80

    variables = {
        'subject_id': subject_id,
        'session_number': session_number,
        'used_sequence': used_sequence,
        'used_sequence_string': used_sequence_string,
        'first_valid_trial': first_valid_trial,
        'number_of_block_elements': number_of_block_elements
    }
    
    return variables

def main():
    # Example usage
    subject = "12345"
    session = 1
    is_offline = True
    is_first_five_random = False

    variables = variable_creation(subject, session, is_offline, is_first_five_random)
    print(variables)

if __name__ == "__main__":
    main()
