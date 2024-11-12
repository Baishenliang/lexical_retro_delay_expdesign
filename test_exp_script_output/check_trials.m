% Check whether the Retrocue Experiment trial output fit the input

%% Load data 
filename = 'Test1111.csv';
data_out = readtable(filename);
filename = 'backup_trial_list_001.xlsx';
data_in = readtable(filename);

%% Compare Sound1
indices_sound1 = 1:8:height(data_out);
Sound1_out = data_out.trial_type(indices_sound1);
Sound1_in = data_in.Syllable_1(1:length(indices_sound1));
Sound1s = [Sound1_out Sound1_in];

% Sound1 checked. What were played by the experiment scripts mathced what
% were generated by the trialslists.

%% Compare Sound2
indices_sound2 = 2:8:height(data_out);
Sound2_out = data_out.trial_type(indices_sound2);
Sound2_in = data_in.Syllable_2(1:length(indices_sound2));
Sound2s = [Sound2_out Sound2_in];

% Sound2 checked. What were played by the experiment scripts mathced what
% were generated by the trialslists.

%% Compare Retrocues
indices_RETRO = 4:8:height(data_out);
RETRO_out = data_out.trial_type(indices_RETRO);
RETRO_in = data_in.Retrocue(1:length(indices_RETRO));
RETROs = [RETRO_out RETRO_in];

% Retrocues checked. What were played by the experiment scripts mathced what
% were generated by the trialslists.

%% Brightness checking
% We cannot check the brightness of the retrocue directly.
% However the brightness values in the Retro_Repeat_WithinBlock.m were
% checked to assign by the same codes to the saving function and the
% displaying functions.

indices_brightness = 4:8:height(data_out);
Brightness_out = data_out.cue_brightness(indices_brightness);
Brightness_out_n = [];
for bn = 1:length(Brightness_out)
    Brightness_out_n(bn)=str2num(Brightness_out{bn});
end
Brightness_in = data_in.Cue_brightness(1:length(indices_brightness));
Brightnesses = [Brightness_out_n' 0.2+0.8*Brightness_in];

% Cue brightness checked. What were played by the experiment scripts mathced what
% were generated by the trialslists.

%% Calculate the time consumed for each block
block1_onset=data_out.onset(1);
block1_offset=data_out.onset(464)+data_out.duration(464);
block1_dur=block1_offset-block1_onset;
disp(strjoin(['Block1 duration ' num2str(block1_dur/60) " mins"],""))
% Block1 duration 8.2314 mins

block2_onset=data_out.onset(465);
block2_offset=data_out.onset(928)+data_out.duration(829);
block2_dur=block2_offset-block2_onset;
disp(strjoin(['Block2 duration ' num2str(block2_dur/60) " mins"],""))
% Block2 duration 8.2319 mins

%% Calculate the time for each trial stage
indices_sound1 = 1:8:height(data_out);
Sound1len_out = data_out.duration(indices_sound1);
histogram(Sound1len_out)

indices_sound2 = 2:8:height(data_out);
Sound2len_out = data_out.duration(indices_sound2);
histogram(Sound2len_out)

indices_Delay1 = 3:8:height(data_out);
Delay1len_out = data_out.duration(indices_Delay1);
histogram(Delay1len_out)

indices_Retro = 4:8:height(data_out);
Retrolen_out = data_out.duration(indices_Retro);
histogram(Retrolen_out)

indices_Delay2 = 5:8:height(data_out);
Delay2len_out = data_out.duration(indices_Delay2);
histogram(Delay2len_out)

indices_Go = 6:8:height(data_out);
Golen_out = data_out.duration(indices_Go);
histogram(Golen_out)

indices_Resp = 7:8:height(data_out);
Resplen_out = data_out.duration(indices_Resp);
histogram(Resplen_out)

indices_ISI = 8:8:height(data_out);
ISIlen_out = data_out.duration(indices_ISI);
histogram(ISIlen_out)

Resp_ISI=Resplen_out+ISIlen_out;
histogram(Resp_ISI);
