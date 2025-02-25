
%% first create a subject folder, e.g. D29/lexical_dr_2x_within_nodelay/part1/ and place task .edf file there
% create a subject case below and fill in variables
clear;
subj_task = 'D120';
trigger_chan_index = [];
mic_chan_index = [];

%TASKS	
% 012   Retro Cue

switch subj_task

    case 'D117_012' % Retro Cue
        cd '.\data'
        taskstim = 'Retro_Cue';
        subj = 'D117';
        edf_filename = 'D117 241208 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D117_Block_1_TrialData.mat';
        taskdate = '241208'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 257; % DC1
        mic_chan_index = 258; % DC1+1
        neural_chan_index = [1:60, 65:122, 129:233];

    case 'D120_012' % Retro Cue
        cd '.\data'
        taskstim = 'Retro_Cue';
        subj = 'D117';
        edf_filename = 'D117 241208 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D117_Block_1_TrialData.mat';
        taskdate = '241208'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 257; % DC1
        mic_chan_index = 258; % DC1+1
        neural_chan_index = [1:60, 65:122, 129:233];

end

load(ptb_trialInfo);
trialInfoAll = []; 
trialInfoAll = [trialInfoAll trialInfo];
trialInfo = trialInfoAll;
save('trialInfo', 'trialInfo');

%% for first subject task, determine neural_chan_index, trigger_chan_index, and mic_chan_index
% once these are determined for a subject, they are the same across tasks
h = edfread_fast(edf_filename);
labels = h.label;
% examine labels variable and determine the indices of neural channels
% (Exclude ones that start with C, EKG, Event, TRIG, OSAT, PR, Pleth, etc.
    % DO NOT INCLUDE EEG CHANNELS! - write EEG down in separate text file note copied to all task folders for same subject
% fill in the above case information for neural_chan()
    % see case D29_002_1 for an example on how to skip channels

%% extract trigger channel and mic channel from edf and save as trigger.mat and mic.mat
if strcmp(h.label(end),'EDFAnnotations')
[~,d] = edfread_fast(edf_filename,1:length(h.label)-1);
else
    [~,d] = edfread_fast(edf_filename);
end
%[~,d] = edfread(edf_filename, 'machinefmt', 'ieee-le'); % use if you get a
%memory error for edfread_fast;
if ~isempty(trigger_chan_index)
    trigger = d(trigger_chan_index,:);
    save('trigger', 'trigger');
    %save('trigger2', 'trigger');
    %if there are multiple files, also save as trigger1, trigger2, etc.

end

if ~isempty(trigger_chan_index)
    mic = d(mic_chan_index,:);
    save('mic', 'mic');
    %save('mic2', 'mic');
    %if there are multiple files, also save as mic1, mic2, etc.

end

%% make *.ieeg.dat file
filename=[ieeg_prefix taskdate '.ieeg.dat'];
fid=fopen(filename,'w');
fwrite(fid,d(neural_chan_index,:),'float');
fclose(fid);
write_experiment_file;
% manually copy .ieeg.dat into [taskdate]/[rec]/
% manually copy experiment.mat into mat

%% manually copy maketrigtimes.m into subject folder and edit / run it to generate trigTimes.mat
% see trigger_walker.m if you have a noisy trigger channel and need to
% estimate / interpolate / extrapolate an auditory Onset																	  												

%% for subjects D26 and newer, audio onset is 0.0234 samples after each trigger
load trigTimes.mat;
%load trigTimes2.mat; %(for multiple files)
trigTimes_audioAligned = trigTimes + ceil(.0234 * h.frequency(1));
save('trigTimes_audioAligned', 'trigTimes_audioAligned');

%% (optional) run view_stim_wavs_on_neural_mic.m to visualize the alignment between microphone and stimulus waves


%% create a generic Trials.mat (for Retro Cue)

load trialInfo.mat;
load trigTimes.mat;

if iscell(trialInfo)
    trialInfo = cell2mat(trialInfo);
end

h = edfread_fast(edf_filename);
Trials = struct();
Rec_onsets = [];
trigT_idx = 0;
for A=1:numel(trialInfo) % change to number of trials
    if A==1
        % block 1 starting: get the block 1 record onsets
        trigT_idx=trigT_idx+1;
        Rec_onsets=floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));
    else
        block_current=trialInfo(A).block;
        block_last=trialInfo(A-1).block;
        if block_last~=block_current
            % block N starting: get the block N record onsets
            trigT_idx=trigT_idx+1;
            Rec_onsets=[Rec_onsets,...
                floor(trigTimes(trigT_idx) * 30000 / h.frequency(1))];
        end
    end

    % Info
    Trials(A).Subject=subj;
    Trials(A).Trial=A;
    Trials(A).Rec=rec;
    Trials(A).Day=taskdate;
    Trials(A).FilenamePrefix=[ieeg_prefix taskdate];

    % Get Auditory1 Start
    trigT_idx=trigT_idx+1;
    Trials(A).audio1Start = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    % Get Auditory2 Start
    trigT_idx=trigT_idx+1;
    Trials(A).audio2Start = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    % Test trigger times for Auditory 1 2 starts
    Aud_onset_diff_from_trialInfo = trialInfo(A).audio2Start - trialInfo(A).audio1Start;
    Aud_onset_diff_from_Trials = (Trials(A).audio2Start - Trials(A).audio1Start)/3e4;
    if abs(Aud_onset_diff_from_trialInfo-Aud_onset_diff_from_Trials)>=0.01
        % Report a misalignment if it is more than 10ms gap
        error('Auditory gap not matched with trialInfo')
    else
        disp(['Auditory gap matched with trialInfo with ', ...
            num2str((Aud_onset_diff_from_trialInfo-Aud_onset_diff_from_Trials)*1e3), ' gap in ms']);
    end

    % Get Retrocue Start
    trigT_idx=trigT_idx+1;
    Trials(A).RetroStart = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    if ~strcmp(trialInfo(A).cue,'0')

        % If not a DROP BOTH trial, get Go Start
        trigT_idx=trigT_idx+1;
        Trials(A).GoStart = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));
    else
        Trials(A).GoStart=Trials(A).RetroStart;
    end

end

save('Trials.mat', 'Trials');
save('Rec_onsets.mat','Rec_onsets');
%if there are multiple files, also save as Trials1, Trials2, etc.