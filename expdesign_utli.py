# expdesign_utli.py

def calculate_experiment_design(exp_totaltime, block_gap, block_length):
    """
    Calculate the number of blocks and remaining time for the experimental design.

    Parameters:
    exp_totaltime (int): Total time available for the experiment in seconds.
    block_gap (int): Minimum gap between blocks in seconds.
    block_length (int): Maximum length for each block in seconds.
    ana_con_trial_num (int): Number of trials per block (used for display only, not in calculation).

    Returns:
    tuple: Number of blocks and remaining time.
    """
    max_blocks = 0
    remaining_time = exp_totaltime

    # Calculate the maximum number of blocks
    while (max_blocks + 1) * block_length + max_blocks * block_gap <= exp_totaltime:
        max_blocks += 1

    # Calculate remaining time
    total_time_used = max_blocks * block_length + (max_blocks - 1) * block_gap
    remaining_time = exp_totaltime - total_time_used

    # Print the results
    print(f"Maximum number of blocks: {max_blocks}")
    print(f"Remaining time: {remaining_time / 60:.2f} minutes")

def miniblock_com_math(stim, retro,method):
    """
    Each miniblock should contain all combinations of syllable*retrocue.
    This function then calculate the number of trials that a miniblock should at least have to fulfill the requirement statred by "method".

    stim, delay, retro: dictionaries with parameters.
    method: (1) exhaustive: list all the potential combinations.
    """
    import itertools
    stim_syllables=stim["syllables"]
    retrocue_types=retro["retro_names"]
    if method == 'exhaustive':
        stim_combinations = list(itertools.permutations(stim_syllables, 2))
        trials_per_miniblock = len(stim_combinations) * len(retrocue_types)
        return stim_combinations, trials_per_miniblock

def miniblock_length_math(trials_per_miniblock, stim, delay, retro, exp_totaltime, block_gap, block_length):
    """
    Each miniblock should contain all combinations of syllable*retrocue.
    This function then calculate the maximal number of miniblocks that a block can contain.
    """

    # Extracting parameters from the stimulus dictionary
    syllable_len = stim["length"]
    syllable_gap = stim["gap"]

    # Extracting parameters from the delay dictionary
    delay1_length = delay["delay1_length"]
    delay2_length = delay["delay2_length"]
    response_length = delay["response_length"]
    iti = delay["iti"]

    # Extracting parameters from the retrocue dictionary
    retro_length = retro["retro_length"]

    # Calculate the duration of a single trial
    trial_length = (syllable_len * 2) + syllable_gap + \
                   delay1_length + retro_length + delay2_length + \
                   response_length + iti

    miniblock_length = trial_length*trials_per_miniblock

    # Calculate how many complete trials can fit within the block
    miniblock_per_block = block_length // miniblock_length  # Using integer division to get complete trial count

    # Current block info
    current_remaining_time = block_length % miniblock_length

    print(f"Average trial length: {trial_length:.2f} seconds")
    print(f"Average miniblock length: {miniblock_length:.2f} seconds, i.e., {miniblock_length/60:.2f} minutes")
    print(f"Remaining time: {current_remaining_time:.2f} seconds")
    print(f"For the given parameters, each block contains: {miniblock_per_block:.0f} miniblocks")

    # Calculate the number of blocks and optimal block length
    best_block_length = None
    min_idle_time = float('inf')
    optimal_block_count = 0

    for block_length in range(int(miniblock_length), int(exp_totaltime) // 2):  # reasonable range for block length
        miniblocks_per_block = block_length // miniblock_length
        remaining_time = block_length % miniblock_length

        total_block_time = miniblocks_per_block * miniblock_length + remaining_time
        total_blocks = exp_totaltime // total_block_time
        total_time_used = total_blocks * total_block_time

        idle_time = exp_totaltime - total_time_used - (total_blocks - 1) * block_gap

        if idle_time < min_idle_time:
            min_idle_time = idle_time
            best_block_length = block_length
            optimal_block_count = total_blocks

    print(f"Suggested block length: {best_block_length:.0f} seconds, i.e., {best_block_length/60:.2f} minutes")
    print(f"Suggested block counts: {optimal_block_count:.0f}")