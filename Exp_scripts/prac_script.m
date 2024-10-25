%% Add PTB in path
addpath(genpath('D:\PTB\Psychtoolbox-3-3.0.19.14\Psychtoolbox'));
%% Try play sound

InitializePsychSound(1);
% devices = PsychPortAudio('GetDevices');
% [playbackdevID,capturedevID] = getDevices;
playbackdevID=3;
capturedevID=1;
freqS=44100;
nrchannels=2;

tPredictedVisualOnsettPredictedVisualOnset=0;

pahandle = PsychPortAudio('Open', playbackdevID, 1+8, 2, freqS, nrchannels,0, 0.015);

tone500=audioread(fullfile('stim','tone.wav'));

stim_Tags = {'she','do','ma'};

[sound_i, ~] = audioread(fullfile('stim',[stim_Tags{1},'.wav']));
[sound_u, ~] = audioread(fullfile('stim',[stim_Tags{2},'.wav']));
[sound_a, fs] = audioread(fullfile('stim',[stim_Tags{3},'.wav']));

soundBuffer{1,1}=PsychPortAudio('OpenSlave', pahandle,1,2);
PsychPortAudio('FillBuffer', soundBuffer{1,1}, [sound_i,sound_i]');

soundBuffer{1,2}=PsychPortAudio('OpenSlave', pahandle,1,2);
PsychPortAudio('FillBuffer', soundBuffer{1,2},  [sound_u,sound_u]');

soundBuffer{1,3}=PsychPortAudio('OpenSlave', pahandle,1,2);
PsychPortAudio('FillBuffer', soundBuffer{1,3}, [sound_a,sound_a]');

soundBuffer{1,4}=PsychPortAudio('OpenSlave', pahandle,1,2);
PsychPortAudio('FillBuffer', soundBuffer{1,4}, [tone500,tone500]');

PsychPortAudio('Start', pahandle,0,0);

for soundID =1:4
    PsychPortAudio('Start',soundBuffer{1, soundID },1,tPredictedVisualOnsettPredictedVisualOnset,0);
    pause(0.5);
    PsychPortAudio('Stop',soundBuffer{1, soundID });
end

PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);
