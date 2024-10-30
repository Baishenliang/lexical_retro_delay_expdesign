function Retro_Repeat_WithinBlock(subject,practice,startblock)
% Retro_Repeat_WithinBlock(subject,practice,startblock)
% subject = subject number
% practice =  practice or full task. 1 = 12 trial practice run, 2 = 2 x 42 trials
% startblock = block to start from.  1 if new, >1 if needing to finish from
%
% previously run task

sca;
% [playbackdevID,capturedevID] = getDevices;
playbackdevID=3;
capturedevID=1;

%playbackdevID = 7; %3; % 4 for usb amp, 3 without
%capturedevID = 6; %1; % 2 for usb amp, 1 without
%subject = 'Test2';
c = clock;
subjectDir = fullfile('data', [num2str(subject), '_' num2str(c(1)) num2str(c(2)) num2str(c(3)) num2str(c(4)) num2str(c(5))]);

%============================================
%        load the sounds
%============================================

%stim_Tags = {'she','do','ma'};
stim_Tags = {'click1','click2','click3'};

retro_Tags = {"REP_BTH","REV_BTH","REP_1ST","REP_2ND","DRP_BTH"};

[sound_i, ~] = audioread(fullfile('stim',[stim_Tags{1},'.wav']));
[sound_u, ~] = audioread(fullfile('stim',[stim_Tags{2},'.wav']));
[sound_a, fs] = audioread(fullfile('stim',[stim_Tags{3},'.wav']));
[tone500, ~]=audioread(fullfile('stim','tone.wav'));

len_i = length(sound_i);
len_u = length(sound_u);
len_a = length(sound_a);

max_len = max([len_i, len_u, len_a]);

sound_i = padarray(sound_i, [(max_len - len_i)/2, 0], 0, 'both');
sound_u = padarray(sound_u, [(max_len - len_u)/2, 0], 0, 'both');
sound_a = padarray(sound_a, [(max_len - len_a)/2, 0], 0, 'both');

%============================================
%        experiment parameter settings
%============================================

if practice==1
    nBlocks = 1;
    fileSuff = '';
else
    nBlocks = 4;
    fileSuff = '_Pract';
end

trialCount=0;
blockCount=0;
%trialEnd=84; %54
nrchannels_rec = 1;
nrchannels_play = 2;
iBStart=startblock;
freqS = fs;
freqR = 44100; %20000;
baseCircleDiam=75; % diameter of

repetitions = 1;
StartCue = 0;
WaitForDeviceStart = 1;

trialInfo=[];
if exist(subjectDir,'dir')
    dateTime=strcat('_',datestr(now,30));
    subjectDir=strcat(subjectDir,dateTime);
    mkdir(subjectDir)
elseif ~exist(subjectDir,'dir')
    mkdir(subjectDir)
end

% Initialize Sounddriver
InitializePsychSound(1);

%============================================
%           load trials infomation
%============================================

[~,block_No,Syll1_No,Syll2_No,Retro_No,Retro_Brightness]=read_trials(subject,stim_Tags,retro_Tags);

%============================================
%                screen setup
%============================================

% Screen Setup
PsychDefaultSetup(2);
% Get the screen numbers
screens = Screen('Screens');
% Select the external screen if it is present, else revert to the native
% screen
screenNumber = max(screens);
% Define black, white and grey
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;
% Open an on screen window and color it grey
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
%[window, windowRect] = PsychImaging('OpenWindow', screenNumber,black,[0 0 500 500]);

% Set the blend funnction for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
ifi = Screen('GetFlipInterval', window);
% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(windowRect);
% Set the text size
Screen('TextSize', window, 50);

% Circle stuff for photodiode
baseCircle = [0 0 baseCircleDiam baseCircleDiam];
%centeredCircle = CenterRectOnPointd(baseCircle, screenXpixels-0.5*baseCircleDiam, screenYpixels-0.5*baseCircleDiam); %
centeredCircle = CenterRectOnPointd(baseCircle, screenXpixels-0.5*baseCircleDiam, 1+0.5*baseCircleDiam); %

circleColor1 = [1 1 1]; % white
circleColor2 = [0 0 0]; % black
% Query the frame duration

% Ready Loop
while ~KbCheck
    % Flip to the screen
    DrawFormattedText(window, 'If you see the cue Yes/No, please say Yes for a word and No for a nonword. \nIf you see the cue Repeat, please repeat the word/nonword. \nPress any key to start. ', 'center', 'center', [1 1 1],58);

    Screen('Flip', window);
    WaitSecs(0.001);
end

%============================================
%           Experiment loop
%============================================
% Set the text size

% Block Loop
for iB=iBStart:nBlocks %nBlocks;

    trial_idx=find(block_No==iB);
    if practice==1
        trial_idx=trial_idx(1:12);
    end

    syll1_trials=Syll1_No(trial_idx);
    syll2_trials=Syll2_No(trial_idx);
    retro_trials=Retro_No(trial_idx);
    retro_brightness_trials=Retro_Brightness(trial_idx);

    Screen('TextSize', window, 100);

    nTrials=84; %168/4; %rotNumb*3;

    cueTimeBaseSeconds= 1  ; % 1.5 up to 5/26/2019 % 0.5 Base Duration of Cue s
    gapTimeSound12=0.35; % Time gap between sound1 and sound2
    delTimeBaseSecondsA = 2; % 0.75 Base Duration of Del s
    goTimeBaseSeconds = 0.5; % 0.5 Base Duration Go Cue Duration s
    respTimeSecondsA = 2.5; % 1.5 Response Duration s
    isiTimeBaseSeconds = 0.87; % 0.5 Base Duration of ISI s

    cueTimeJitterSeconds = 0.2; % 0.25; % Cue Jitter s
    delTimeJitterSeconds = 0.2;% 0.5; % Del Jitter s
    goTimeJitterSeconds = 0.2;% 0.25; % Go Jitter s
    isiTimeJitterSeconds = 0.2; % 0.5; % ISI Jitter s

    soundBlockPlay=[];

    for i=1:length(trial_idx) %trialEnd; %42

        %==================== five retrocue types   ===================

        if retro_trials(i)==1
            trigVal=10*syll1_trials(i)+syll2_trials(i);
        elseif retro_trials(i)==2
            trigVal=100+10*syll1_trials(i)+syll2_trials(i);
        elseif retro_trials(i)==3
            trigVal=200+10*syll1_trials(i)+syll2_trials(i);
        elseif retro_trials(i)==4
            trigVal=300+10*syll1_trials(i)+syll2_trials(i);
        elseif retro_trials(i)==5
            trigVal=400+10*syll1_trials(i)+syll2_trials(i);
        end

        switch syll1_trials(i)
            case 1 % she
                soundBlockPlay{i}.sound1=sound_i;
            case 2 % do
                soundBlockPlay{i}.sound1=sound_u;
            case 3 % ma
                soundBlockPlay{i}.sound1=sound_a;
        end

        switch syll2_trials(i)
            case 1 % she
                soundBlockPlay{i}.sound2=sound_i;
            case 2 % do
                soundBlockPlay{i}.sound2=sound_u;
            case 3 % ma
                soundBlockPlay{i}.sound2=sound_a;
        end

        soundBlockPlay{i}.name1=stim_Tags{syll1_trials(i)};
        soundBlockPlay{i}.name2=stim_Tags{syll2_trials(i)};
        soundBlockPlay{i}.Trigger=trigVal;
        %========================================================================

    end

    %binCodeVals=repmat(binCodeVals,3,1);

    % Setup recording!
    pahandle2 = PsychPortAudio('Open', capturedevID, 2, 0, freqR, nrchannels_rec,0, 0.015);
    % Preallocate an internal audio recording  buffer with a capacity of 10 seconds:
    PsychPortAudio('GetAudioData', pahandle2, 9000); %nTrials
    PsychPortAudio('Start', pahandle2, 0, 0, 1);

    % Setup audio replay
    pahandle = PsychPortAudio('Open', playbackdevID, 1+8, 2, freqS, nrchannels_play,0, 0.015);
    PsychPortAudio('Volume', pahandle, 1); % volume

    % load sound buffer
    soundBuffer{1,1}=PsychPortAudio('OpenSlave', pahandle,1,2);
    PsychPortAudio('FillBuffer', soundBuffer{1,1}, [sound_i,sound_i]');
    
    soundBuffer{1,2}=PsychPortAudio('OpenSlave', pahandle,1,2);
    PsychPortAudio('FillBuffer', soundBuffer{1,2},  [sound_u,sound_u]');
    
    soundBuffer{1,3}=PsychPortAudio('OpenSlave', pahandle,1,2);
    PsychPortAudio('FillBuffer', soundBuffer{1,3}, [sound_a,sound_a]');
    
    soundBuffer{1,4}=PsychPortAudio('OpenSlave', pahandle,1,2);
    PsychPortAudio('FillBuffer', soundBuffer{1,4}, [tone500,tone500]');

    % Start pahandle
    PsychPortAudio('Start', pahandle,0,0);

    % Play the tone
    %PsychPortAudio('Start', pahandle, repetitions, StartCue, WaitForDeviceStart);
    PsychPortAudio('Start',soundBuffer{1, 4},repetitions,StartCue,WaitForDeviceStart);
    PsychPortAudio('Volume', pahandle, 0.5);

    toneTimeSecs = (freqS+length(tone500))./freqS; %max(cat(1,length(kig),length(pob)))./freqS;
    toneTimeFrames = ceil(toneTimeSecs / ifi);
    for i=1:toneTimeFrames

        DrawFormattedText(window, '', 'center', 'center', [1 1 1]);
        % Flip to the screen
        Screen('Flip', window);
    end

    PsychPortAudio('Stop',soundBuffer{1, 4});

    % Rprelat = PsychPortAudio('LatencyBias', pahandle, 0) ;%#ok<NOPRT,NASGU>
    % postlat = PsychPortAudio('LatencyBias', pahandle);

    %
    %while ~kbCheck
    ifi_window = Screen('GetFlipInterval', window);
    suggestedLatencySecs = 0.015;
    waitframes = ceil((2 * suggestedLatencySecs) / ifi_window) + 1;
    Priority(2);

    for iTrials=1:length(trial_idx) %trialEnd ;%nTrials %nTrials;

        %============================================
        %         get prepared for a trial
        %============================================

        
        % ! Currently I don't have the pase_script
        % if pause_script(window)
        %     PsychPortAudio('close');
        %     sca;
        %     return;
        % end

        switch retro_trials(iTrials)
            case 1 % REP_BTH
                cue='1 2';
            case 2 % REV_BTH
                cue='2 1';
            case 3 % REP_1ST
                cue='1';
            case 4 % REP_2ND
                cue='2';
            case 5 % DRP_BTH
                cue='0';
        end

        % WE DONT NEED THIS
        sound1=soundBlockPlay{iTrials}.sound1;
        sound1=sound1(:,1);
        sound2=soundBlockPlay{iTrials}.sound2;
        sound2=sound2(:,1);

        go='Speak'; 

        delTimeBaseSeconds=delTimeBaseSecondsA;
        respTimeSeconds=respTimeSecondsA;

        sound1TimeSecs = length(sound1)./freqS; 
        sound1TimeFrames = ceil(sound1TimeSecs / ifi);
        sound2TimeSecs = length(sound2)./freqS; 
        sound2TimeFrames = ceil(sound2TimeSecs / ifi);
        gapSound12TimeFrames = ceil(gapTimeSound12 / ifi);

        cueTimeBaseFrames = round((cueTimeBaseSeconds+(cueTimeJitterSeconds*rand(1,1))) / ifi);

        delTimeSeconds = delTimeBaseSeconds + delTimeJitterSeconds*rand(1,1);
        delTimeFrames = round(delTimeSeconds / ifi );
        goTimeSeconds = goTimeBaseSeconds +goTimeJitterSeconds*rand(1,1);
        goTimeFrames = round(goTimeSeconds / ifi);
        respTimeFrames = round(respTimeSeconds / ifi);

        % write trial structure
        flipTimes = zeros(1,cueTimeBaseFrames);
        trialInfo{trialCount+1}.cue = cue;
        trialInfo{trialCount+1}.cue_brightness = retro_brightness_trials(iTrials);
        trialInfo{trialCount+1}.sound1 = soundBlockPlay{iTrials}.name1;%trialStruct.sound{trialShuffle(2,iTrials)};
        trialInfo{trialCount+1}.sound2 = soundBlockPlay{iTrials}.name2;%trialStruct.sound{trialShuffle(2,iTrials)};
        trialInfo{trialCount+1}.go = go;
        trialInfo{trialCount+1}.cueTime=GetSecs;   % !!!!!!!!!!!!!Change it!!!!!!!!!!!!!!!!!
        trialInfo{trialCount+1}.block = iB;
        %trialInfo{trialCount+1}.cond = trialShuffle(4,iTrials);
        trialInfo{trialCount+1}.cueStart = GetSecs;  % !!!!!!!!!!!!!Change it!!!!!!!!!!!!!!!!!
        trialInfo{trialCount+1}.Trigger=soundBlockPlay{iTrials}.Trigger;

        %============================================
        %                Play sound 1
        %============================================

        %Play Sound
        Screen('FillOval', window, circleColor1, centeredCircle, baseCircleDiam);
        %PsychPortAudio('FillBuffer', pahandle, sound1');

        tWhen = GetSecs + (waitframes - 0.5)*ifi_window;
        tPredictedVisualOnset = PredictVisualOnsetForTime(window, tWhen);
        sound1_play=soundBuffer{1, Syll1_No(iTrials)};
        %PsychPortAudio('Start', pahandle, 1, tPredictedVisualOnset, 0);
        PsychPortAudio('Start',sound1_play,repetitions,tPredictedVisualOnset,0);

        [~,trigFlipOn] = Screen('Flip', window, tWhen);
        offset = 0;
        while offset == 0
            status = PsychPortAudio('GetStatus', sound1_play);
            offset = status.PositionSecs;
            WaitSecs('YieldSecs', 0.001);
        end

        trialInfo{trialCount+1}.audioStart = status.StartTime;
        trialInfo{trialCount+1}.audioAlignedTrigger = trigFlipOn;
        fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (status.StartTime - trigFlipOn)*1000.0)

        % Draw blank for duration of sound1
        for i=1:sound1TimeFrames

            DrawFormattedText(window, '', 'center', 'center', [1 1 1]);
            % Flip to the screen
            Screen('Flip', window);
        end

        PsychPortAudio('Stop',sound1_play);

        %============================================================
        %            GAP between sound 1 and sound 2
        %============================================================

        % Draw blank for duration of sound
        for i=1:gapSound12TimeFrames
            DrawFormattedText(window, '', 'center', 'center', [1 1 1]);
            % Flip to the screen
            Screen('Flip', window);
        end

        %============================================
        %                Play sound 2
        %============================================

        %Play Sound
        Screen('FillOval', window, circleColor1, centeredCircle, baseCircleDiam);
        tWhen = GetSecs + (waitframes - 0.5)*ifi_window;
        tPredictedVisualOnset = PredictVisualOnsetForTime(window, tWhen);
        sound2_play=soundBuffer{1, Syll2_No(iTrials)};
        %PsychPortAudio('Start', pahandle, 1, tPredictedVisualOnset, 0);
        PsychPortAudio('Start',sound2_play,repetitions,tPredictedVisualOnset,0);

        [~,trigFlipOn] = Screen('Flip', window, tWhen);
        offset = 0;
        while offset == 0
            status = PsychPortAudio('GetStatus', sound2_play);
            offset = status.PositionSecs;
            WaitSecs('YieldSecs', 0.001);
        end

        trialInfo{trialCount+1}.audioStart = status.StartTime;
        trialInfo{trialCount+1}.audioAlignedTrigger = trigFlipOn;
        fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (status.StartTime - trigFlipOn)*1000.0)

        % Draw blank for duration of sound
        for i=1:sound2TimeFrames

            DrawFormattedText(window, '', 'center', 'center', [1 1 1]);
            % Flip to the screen
            Screen('Flip', window);
        end

        PsychPortAudio('Stop',sound2_play);

        %============================================
        %               Delay 1
        %============================================


        trialInfo{trialCount+1}.delStart=GetSecs;
        for i=1:delTimeFrames
            Screen('Flip', window);
        end
        trialInfo{trialCount+1}.delEnd=GetSecs;

        %============================================
        %               RetroCue
        %============================================

        % Draw Retrocue text

        retroB=retro_brightness_trials(iTrials);
        for i = 1:cueTimeBaseFrames
            % Draw oval for 10 frames (duration of binary code with start/stop bit)
            if i<=3
                Screen('FillOval', window, circleColor1, centeredCircle, baseCircleDiam); % leave on!
            end

            if i<=0.625*cueTimeBaseFrames
                % Draw text
                DrawFormattedText(window, cue, 'center', 'center', [1 1 1]*retroB);
            end
            % Flip to the screen
            flipTimes(1,i) = Screen('Flip', window);
        end
        trialInfo{trialCount+1}.cueEnd=GetSecs;


        %============================================
        %               Delay 2
        %============================================

        trialInfo{trialCount+1}.delStart=GetSecs;
        for i=1:delTimeFrames
            Screen('Flip', window);
        end

        trialInfo{trialCount+1}.delEnd=GetSecs;


        %============================================
        %               Go
        %============================================
        if retro_trials(iTrials)~=5 % Repeat both
            trialInfo{trialCount+1}.goStart=GetSecs;
            for i=1:goTimeFrames
                DrawFormattedText(window, go, 'center', 'center', [1 1 1]);
                Screen('Flip', window);
            end
            
            trialInfo{trialCount+1}.goEnd=GetSecs;
        else
            trialInfo{trialCount+1}.goEnd=trialInfo{trialCount+1}.delEnd;
        end

        %============================================
        %               Response
        %============================================

        if retro_trials(iTrials)~=5 % Repeat both
            trialInfo{trialCount+1}.respStart=GetSecs;
            for i=1:respTimeFrames
                %  DrawFormattedText(window,'','center','center',[1 1 1]);
                % Flip to the screen
                Screen('Flip', window);
            end
    
            trialInfo{trialCount+1}.respEnd=GetSecs;
        else
            trialInfo{trialCount+1}.respEnd=trialInfo{trialCount+1}.delEnd;
        end

        %============================================
        %               ISI
        %============================================

        isiTimeSeconds = isiTimeBaseSeconds + isiTimeJitterSeconds*rand(1,1);
        isiTimeFrames=round(isiTimeSeconds / ifi );

        trialInfo{trialCount+1}.isiStart=GetSecs;
        for i=1:isiTimeFrames
            DrawFormattedText(window,'' , 'center', 'center', [1 1 1]);
            % Flip to the screen
            Screen('Flip', window);
        end

        trialInfo{trialCount+1}.isiEnd=GetSecs;
        trialInfo{trialCount+1}.flipTimes = flipTimes;
        save([subjectDir '/' num2str(subject) '_Block_' num2str(iBStart) fileSuff '_TrialData.mat'],'trialInfo')

        trialCount=trialCount+1;

        %       end
        %tmp1=0;
    end

    Priority(0);
    [audiodata offset overflow tCaptureStart] = PsychPortAudio('GetAudioData', pahandle2);
    filename = ([num2str(subject) '_Block_' num2str(iB) fileSuff '_AllTrials.wav']);
    audiowrite([subjectDir '/' filename],audiodata,freqR);
    PsychPortAudio('Stop', pahandle2);
    PsychPortAudio('Close', pahandle2);

    PsychPortAudio('Stop', pahandle);
    PsychPortAudio('Close', pahandle);

    blockCount=blockCount+1;
    Screen('TextSize', window, 50);

    % % Break Screen
    while ~KbCheck
        % Set the text size

        DrawFormattedText(window, 'Take a short break and press any key to continue', 'center', 'center', [1 1 1]);
        % Flip to the screen
        Screen('Flip', window);
        WaitSecs(0.001);
    end

end
sca
close all
%clear all