% This script read the events.tsv files and process them for response
% coding and ieeg processing
clear all
close all

%% read data
testing_folder='testing_20241112_gTTS';
data_tsv = readtable(fullfile('data',testing_folder,'Test1112_gTTS.csv'));
data_tsv(strcmp(data_tsv{:, 3}, 'Record_onset'), :) = [];
first_stims = readtable(fullfile('data',testing_folder,'first_stims.txt'));
td = first_stims.Var1(1);
load(fullfile('data',testing_folder,"Test1112_gTTS_Block_1_TrialData.mat"));
pc_onset = trialInfo{1,232}.audio1Start;

%% replace the onsets of the data_tsv by trialInfo.
% Dont have to do it in the true experiment data (as the Retrocue task scrips have been updated)
indices_sound1 = 1:8:height(data_tsv);
indices_sound2 = 2:8:height(data_tsv);
indices_retro = 4:8:height(data_tsv);
indices_go = 6:8:height(data_tsv);

f_stims = fopen(fullfile('data',testing_folder,'stims.txt'), 'w');
f_cues = fopen(fullfile('data',testing_folder,'retrocues.txt'),'w');
f_gos = fopen(fullfile('data',testing_folder,'gos.txt'),'w');

% loop for all the trials
for k = 1:length(indices_sound1)

    trial_tmp=[];
    trial_tmp=trialInfo{1,k};

    if trial_tmp.block==5

        audio1Start_trialInfo=trial_tmp.audio1Start-pc_onset;
        fprintf(f_stims, '%.17f\t%.17f\t%s\n', td+audio1Start_trialInfo, ...
            td+audio1Start_trialInfo+data_tsv.duration(indices_sound1(k)), ...
            data_tsv.trial_type{indices_sound1(k)});
    
        audio2Start_trialInfo=trial_tmp.audio2Start-pc_onset;
        fprintf(f_stims, '%.17f\t%.17f\t%s\n', td+audio2Start_trialInfo, ...
            td+audio2Start_trialInfo+data_tsv.duration(indices_sound2(k)), ...
            data_tsv.trial_type{indices_sound2(k)});
            
        retoStart=trial_tmp.del1End-pc_onset;
        fprintf(f_cues, '%.17f\t%.17f\t%s\n', td+retoStart, ...
            td+retoStart+data_tsv.duration(indices_retro(k)), ...
            data_tsv.trial_type{indices_retro(k)});
    
        goStart=trial_tmp.del2End-pc_onset;
        fprintf(f_gos, '%.17f\t%.17f\t%s\n', td+goStart, ...
            td+goStart+data_tsv.duration(indices_go(k)), ...
            data_tsv.trial_type{indices_go(k)});
    end
end

fclose(f_stims);
fclose(f_cues);
fclose(f_gos);
