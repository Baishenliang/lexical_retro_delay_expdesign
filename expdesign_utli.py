# expdesign_utli.py
import pandas as pd
import itertools
import random
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import kstest
import sys

from setuptools.sandbox import save_path


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
    syllables = stim["syllables"]

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
    print(f"For the given parameters, the same sayllble can be repeated \
{(len(syllables) - 1) * int(miniblock_per_block):.0f} times for EACH BLOCK")

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

    print("    ")
    print(f"Suggested block length: {best_block_length:.0f} seconds, i.e., {best_block_length/60:.2f} minutes")
    print(f"Suggested block counts: {optimal_block_count:.0f}")

    num_miniblock_inblock=int(best_block_length // miniblock_length)
    print(f"For the suggested version, the same sayllble can be repeated \
{(len(syllables)-1) * int(optimal_block_count) * num_miniblock_inblock:.0f} times for the ENTIRE EXPERIMENT")

    return num_miniblock_inblock, optimal_block_count

def generate_triallist(num_miniblock_inblock, optimal_block_count, stim, delay, retro):
    """
    This function generates a spreadsheet for the experimental trials.

    Purpose: Create a spreadsheet (e.g., in Excel format) where each row contains information for a trial, including trial number,
    block number, the syllable combination in the encode phase (one syllable per column), the length of delay1, the retrocue type,
    the length of delay2, and the total trial length.

    Requirements:
    1. Exhaustively list all possible syllable combinations, taking into account the order of syllables.
    2. For each syllable combination, exhaustively combine with the retrocue types.
    3. Each miniblock exhaustively presents all trial combinations from steps 1 and 2.
    4. Randomize the order of trials within each miniblock while ensuring:
        (1) The average position of each syllable and retrocue is near the middle of the miniblock to avoid order effects.
        (2) The syllable1, syllable2, and retrocue should be orthogonal to each other (i.e., intra-trial unpredictibility).
            (But this should have meet as we exhaustively list all combinations)
        (3) The syllable pair and retrocue cannot predict the syllable pair and retro cue in the upcomping trial (i.e., inter-trial unpredictibility).
        (4) For retrocue and syllable: consecutive trials should neither be overlapped with retrocue type nor syllable pair.
        (5) Miniblocks within and across subjects shoule be different.

    """

    #Inserted function 1:
    #Function to generate a randomized list of trials that meets the adjacency criteria

    def get_valid_randomized_trials(full_combinations):
        valid_trials = []
        invalid_warn = 0
        available_trials = full_combinations.copy()

        # Randomly pick the first trial
        current_trial = random.choice(available_trials)
        valid_trials.append(current_trial)
        available_trials.remove(current_trial)

        while available_trials:
            # Filter available trials to avoid repeating syllable pairs (regardless of order) and retrocue types
            next_trial_candidates = [
                trial for trial in available_trials
                if set(trial[0]) != set(
                    valid_trials[-1][0])  # Ensure syllable pair differs from the last trial (ignore order)
                   and trial[1] != valid_trials[-1][1]  # Ensure retrocue type is different from the last trial
            ]

            if not next_trial_candidates:
                invalid_warn=1
                break

            next_trial = random.choice(next_trial_candidates)
            valid_trials.append(next_trial)
            available_trials.remove(next_trial)

        return valid_trials,invalid_warn

    #Inserted function 2:
    #
    def plot_histogram(data, title, xlabel,bin_width,save_path):
        """
        Plots a histogram for the given data.

        Args:
        - data (list): Data to plot.
        - title (str): Title of the plot.
        - xlabel (str): Label for the x-axis.
        """
        min_data, max_data = min(data), max(data)
        num_bins = int((max_data - min_data) / bin_width)

        plt.figure()
        plt.hist(data, bins=num_bins, edgecolor='black')
        plt.title(title)
        plt.xlabel(xlabel)
        plt.ylabel('Frequency')


        # Save the plot as a PNG file
        plt.savefig(save_path)
        plt.show()

        plt.close()

    #Inserted function 3:
    #
    def evaluate_trial_distribution(randomized_trials, syllables, retro_names):
        """
        Evaluate the trial distribution for each syllable pair and retrocue individually based on:
        1. Uniformity of occurrence across trials.
        2. Closeness of their position to the midpoint of the trials.
        3. Transition uniformity between consecutive syllable pairs and retrocues.

        Args:
        - randomized_trials (list): A list of randomized trials with syllables and retrocues.
        - syllables (list): List of syllables used in the experiment.
        - retro_names (list): List of retrocue types used in the experiment.

        Returns:
        - syllable_scores (dict): A dictionary containing scores for each syllable pair.
        - retrocue_scores (dict): A dictionary containing scores for each retrocue type.
        """

        num_trials = len(randomized_trials)
        mid_point = num_trials / 2

        # Initialize dictionaries to store counts and positions
        syllable_pairs = list(itertools.permutations(syllables, 2))
        #syllable_counts = {pair: 0 for pair in syllable_pairs}
        #retrocue_counts = {cue: 0 for cue in retro_names}

        syllable_positions = {pair: [] for pair in syllable_pairs}
        retrocue_positions = {cue: [] for cue in retro_names}

        syllable_transitions = {pair: {} for pair in syllable_pairs}
        retrocue_transitions = {cue: {} for cue in retro_names}

        # Loop through trials to record positions and transitions
        for i, trial in enumerate(randomized_trials):
            syllable_pair = tuple(trial[0])  # Keep order in consideration
            retrocue = trial[1]

            # Count occurrences and record positions
            #syllable_counts[syllable_pair] += 1
            syllable_positions[syllable_pair].append(i)
            #retrocue_counts[retrocue] += 1
            retrocue_positions[retrocue].append(i)

            # Track transitions (syllable pairs and retrocues between trials)
            if i > 0:
                prev_syllable_pair = tuple(randomized_trials[i - 1][0])
                prev_retrocue = randomized_trials[i - 1][1]

                if syllable_pair not in syllable_transitions[prev_syllable_pair]:
                    syllable_transitions[prev_syllable_pair][syllable_pair] = 0
                syllable_transitions[prev_syllable_pair][syllable_pair] += 1

                if retrocue not in retrocue_transitions[prev_retrocue]:
                    retrocue_transitions[prev_retrocue][retrocue] = 0
                retrocue_transitions[prev_retrocue][retrocue] += 1

        # Initialize dictionaries for storing scores
        syllable_scores = {}
        retrocue_scores = {}

        # 1. Evaluate syllable pair distribution and transition
        for pair in syllable_pairs:
            #uniformity_score = np.std([syllable_counts[pair]])  # Variance from uniform distribution
            _, uniformity_score = kstest([(pos-1)/(num_trials-1) for pos in syllable_positions[pair]], 'uniform')
            midpoint_score = abs(np.mean(syllable_positions[pair]) - mid_point) if syllable_positions[pair] else float(
                'inf')
            transition_score = np.std(list(syllable_transitions[pair].values())) if syllable_transitions[
                pair] else float('inf')

            syllable_scores[pair] = {
                "uniformity_score": 1 - uniformity_score,
                "midpoint_score": midpoint_score,
                "transition_score": transition_score
            }

        # 2. Evaluate retrocue distribution and transition
        for retrocue in retro_names:
            #uniformity_score = np.std([retrocue_counts[retrocue]])  # Variance from uniform distribution
            _, uniformity_score = kstest([(pos-1)/(num_trials-1) for pos in retrocue_positions[retrocue]], 'uniform')
            midpoint_score = abs(np.mean(retrocue_positions[retrocue]) - mid_point) if retrocue_positions[
                retrocue] else float('inf')
            transition_score = np.std(list(retrocue_transitions[retrocue].values())) if retrocue_transitions[
                retrocue] else float('inf')

            retrocue_scores[retrocue] = {
                "uniformity_score": 1 - uniformity_score,
                "midpoint_score": midpoint_score,
                "transition_score": transition_score
            }

        return syllable_scores, retrocue_scores

    #Inserted function 4:
    #
    def get_valid_trials_sequence(randomized_trials_candidates, stim, retro,threshold):
        """
        Filter and score randomized trial candidates based on individual score criteria.

        Args:
        - randomized_trials_candidates (list): List of all randomized trial sequences.
        - syllables (list): List of syllable pairs.
        - retro_names (list): List of retrocue types.
        - threshold (dict): Dictionary with keys 'uniformity', 'midpoint', and 'transition' representing the max allowed values.

        Returns:
        - best_trial (list): The best randomized trial sequence that meets all criteria.
        """
        print("=====================================================")
        print("Now getting a valid randomized trial sequence.")
        print("=====================================================")
        # Some options for this function
        is_plotting = 0
        # Whether to plot the histograms to explore thresholds for selecting distributions
        ### IMPORTANTANT: must use debug mode when setting thresholds, as the best_trails are invalid.

        syllables=stim["syllables"]
        retro_names=retro["retro_names"]

        valid_trials = []
        all_uniformity_scores = []
        all_midpoint_scores = []
        all_transition_scores = []

        rnd_trial_count=0
        len_trial_counts=len(randomized_trials_candidates)
        for randomized_trials in randomized_trials_candidates:
            rnd_trial_count +=1
            #print(
            #    f"Estimating the {rnd_trial_count} random trial list out of {len_trial_counts}")#

            syllable_scores, retrocue_scores = evaluate_trial_distribution(randomized_trials, syllables, retro_names)

            # Collect all scores for histogram plotting
            if is_plotting:
                for score_dict in [syllable_scores, retrocue_scores]:
                    for scores in score_dict.values():
                        all_uniformity_scores.append(scores["uniformity_score"])
                        all_midpoint_scores.append(scores["midpoint_score"])
                        all_transition_scores.append(scores["transition_score"])

            # Check if all scores for syllable pairs and retrocues meet the threshold
            valid = True
            for score_dict in [syllable_scores, retrocue_scores]:
                for scores in score_dict.values():
                    if (scores["uniformity_score"] > threshold["uniformity"] or
                            scores["midpoint_score"] > threshold["midpoint"] or
                            scores["transition_score"] > threshold["transition"]):
                        valid = False
                        break
                if not valid:
                    break

            # If valid, add to candidate pool
            if valid:
                valid_trials.append(randomized_trials)

        # If setting threshold, plot histograms
        if is_plotting:
            hist_save_path='D:\\bsliang_Coganlabcode\\lexical_retro_delay_expdesign\\'
            plot_histogram(all_uniformity_scores, 'Uniformity Score (1 - p_KStest)', 'Uniformity Score',0.05,hist_save_path+'RND_uniform.png')
            plot_histogram(all_midpoint_scores, 'Midpoint Diff (Mean positions - Midpoint)', 'Midpoint Score',0.5,hist_save_path+'RND_middist.png')
            plot_histogram(all_transition_scores, 'Transitional Prob. Deviance (Std. transProb for each)', 'Transition Score',0.1,hist_save_path+'RND_transprob_dev.png')
        return valid_trials

    #Inserted function 5:
    # Looping the best threshold parameters
    def loop_and_plot_valid_trials(randomized_trials_candidate, stim, retro):
        # Define the ranges for the threshold values
        # Transition is not good. Ingore it.
        uniformity_range = np.arange(0.05, 1, 0.2)
        midpoint_range = np.arange(0, 20, 2)
        #transition_range = np.arange(0.05, 1.05, 0.2)

        results = []

        total_steps = len(list(itertools.product(uniformity_range, midpoint_range)))#, transition_range)))
        # Loop through all combinations of threshold values
        for step, (uniformity, midpoint) in enumerate(
                itertools.product(uniformity_range, midpoint_range), start=1):
            print(f"Step {step} out of {total_steps}")
            threshold = {
                "uniformity": uniformity,
                "midpoint": midpoint,
                "transition": 3
            }

            valid_trials = get_valid_trials_sequence(randomized_trials_candidate, stim, retro, threshold)
            valid_trials_length = len(valid_trials)

            results.append((uniformity, midpoint, valid_trials_length))

        # Convert results to a DataFrame for easier plotting
        df_results = pd.DataFrame(results, columns=['uniformity', 'midpoint', 'valid_trials_length'])

        # Create a 3D plot
        fig = plt.figure()
        ax = fig.add_subplot(111, projection='3d')

        # Scatter plot
        #sc = ax.scatter(df_results['uniformity'], df_results['midpoint'], df_results['transition'],
        #                c=df_results['valid_trials_length'], cmap='viridis')
        sc = ax.scatter(df_results['uniformity'], df_results['midpoint'], df_results['valid_trials_length'])


        # Add color bar
        # cbar = plt.colorbar(sc)
        # cbar.set_label('Length of Valid Trials')

        # Set labels
        ax.set_xlabel('Uniformity')
        ax.set_ylabel('Midpoint')
        ax.set_zlabel('NO. of valid trial sequences')

        plt.title('3D Plot of Valid Trials Length')
        plt.show()

    #Inserted function 6:
    # Get the best valid trial sequencys
    def get_best_trials_sequence(valid_trials):
        # Now score the valid trials to find the best
        is_chosing_the_best_random = 0  # Whether to choose the best randomization plans or just to randomly select from good plans

        best_trials = None
        best_score = float('inf')

        if is_chosing_the_best_random == 1:
            1
            # for randomized_trials in syllable_pairs = list(itertools.permutations(syllables, 2)):
            #     syllable_scores, retrocue_scores = evaluate_trial_distribution(randomized_trials, syllables, retro_names)

            #     # Calculate total score by summing all the individual scores
            #     total_score = 0
            #     for score_dict in [syllable_scores, retrocue_scores]:
            #         for scores in score_dict.values():
            #             total_score += (scores["uniformity_score"] + scores["midpoint_score"] + scores["transition_score"])

            #     # Keep track of the lowest scoring trial
            #     if total_score < best_score:
            #         best_score = total_score
            #         best_trials = randomized_trials
        else:
            best_trials=random.choice(valid_trials)
        return best_trials

    # Function body

    num_miniblock_inblock=int(num_miniblock_inblock)
    optimal_block_count=int(optimal_block_count)

    # Create an empty list to store all trial information
    trial_list = []

    # 1. Generate all possible syllable combinations (taking order into account)
    syllable_combinations = list(itertools.permutations(stim["syllables"], 2))

    # 2. Generate all combinations of syllables and retrocue types
    full_combinations = list(itertools.product(syllable_combinations, retro["retro_names"]))

    # 3. Calculate the number of trials per miniblock
    trials_per_miniblock = len(full_combinations)

    # 4. Loop through each block and miniblock to generate trials
    trial_id = 1
    for block_id in range(1, optimal_block_count + 1):
        for miniblock_id in range(1, num_miniblock_inblock + 1):

            #Repeat this part 1000 times, and for each successful attempt
            #save the `randomized_trials` into `randomized_trials_candidate

            get_RDtrialscomb_maxnum = 1000  # Initialize attempt counter
            get_RDtrialscomb = 1
            randomized_trials_candidate = []  # List to store each valid randomized trial sequence


            # Retry until a valid combination is found or the attempt limit is reached
            while get_RDtrialscomb <= get_RDtrialscomb_maxnum:

                # Randomize the trial order within the miniblock
                attempt_count = 0  # Initialize attempt counter

                # Retry until a valid combination is found or the attempt limit is reached
                while attempt_count < 1000:
                        # Attempt to get a valid randomized order of trials
                        randomized_trials,invalid_warn = get_valid_randomized_trials(full_combinations)
                        print(f"Runing the {get_RDtrialscomb} time of random trial list generation out of {get_RDtrialscomb_maxnum}")
                        if invalid_warn == 0:
                            randomized_trials_candidate.append(randomized_trials)
                            get_RDtrialscomb +=1
                            print(f"**Successfully** made a miniblock with intra-trial unpredictability for Block {block_id}, Miniblock {miniblock_id}")
                            break  # If successful, exit the loop
                        else:
                            attempt_count += 1
                            print(
                                f"Warning: No valid combination found for Block {block_id}, Miniblock {miniblock_id}. Retrying... ({attempt_count})")

                # if attempt_count >= 1000:
                #     print(
                #         f"Error: Failed to generate valid trial order after 1000 attempts for Block {block_id}, Miniblock {miniblock_id}. Exiting script.")
                #     sys.exit()  # Exit the entire script after 1000 failed attempts


            # Guessing the best threshold combinations
            #loop_and_plot_valid_trials(randomized_trials_candidate, stim, retro)

            threshold = {
                "uniformity": 0.7,  # The standard deviation of the trial distribution should be less than 1
                "midpoint": 10,  # The mean position of the syllable/retrocue should be within 3 trials of the midpoint
                "transition": 3  # The standard deviation of transition counts between trials should be less than 0.5
            }

            valid_trials = get_valid_trials_sequence(randomized_trials_candidate, stim, retro,threshold)
            best_trials = get_best_trials_sequence(valid_trials)


            for trial in best_trials:
                # Extract the syllable pair and retrocue type for the trial
                syllables, retrocue = trial

                # Construct trial information
                trial_info = {
                    "Trial": trial_id,
                    "Block": block_id,
                    "Miniblock": miniblock_id,
                    "Syllable_1": syllables[0],
                    "Syllable_2": syllables[1],
                    "Retrocue": retrocue,
                    "Delay1_Length": delay["delay1_length"],
                    "Delay2_Length": delay["delay2_length"],
                    "Total_Trial_Length": stim["length"] * 2 + stim["gap"] + delay["delay1_length"] + retro[
                        "retro_length"] + delay["delay2_length"]
                }

                # Append the trial to the trial list
                trial_list.append(trial_info)
                trial_id += 1

    # Convert the trial list to a DataFrame
    df_trials = pd.DataFrame(trial_list)

    # Save the trial list to an Excel file
    df_trials.to_excel("D:\\bsliang_Coganlabcode\\lexical_retro_delay_expdesign\\trial_list.xlsx", index=False)

    return df_trials
