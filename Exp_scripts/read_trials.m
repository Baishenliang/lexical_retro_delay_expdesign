function [trial_No,block_No,Syll1_No,Syll2_No,Retro_No]=read_trials(subject,stim_Tags,retro_Tags)

filename = fullfile('trials',['subject_',num2str(subject),'_trial_list.xlsx']);
data = readtable(filename);
numRows = height(data);

trial_No =  nan(numRows, 1);
block_No =  trial_No;
Syll1_No =  trial_No;
Syll2_No =  trial_No;
Retro_No =  trial_No;

for i = 1:numRows

    trial_No(i) =  data.Trial(i);
    block_No(i) =  data.Block(i);

    Syll1 = data.Syllable_1(i);
    switch Syll1{1}
        case stim_Tags{1}
            % /i/
            Syll1_No(i) =  1;
        case stim_Tags{2}
            % /u/
            Syll1_No(i) =  2;
        case stim_Tags{3}
            % /a/
            Syll1_No(i) =  3;
    end

    Syll2 = data.Syllable_2(i);
    switch Syll2{1}
        case stim_Tags{1}
            % /i/
            Syll2_No(i) =  1;
        case stim_Tags{2}
            % /u/
            Syll2_No(i) =  2;
        case stim_Tags{3}
            % /a/
            Syll2_No(i) =  3;
    end

    Retro =  data.Retrocue(i);
    switch Retro{1}
        case retro_Tags{1}
            % "REP_BTH"
            Retro_No(i) =  1;
        case retro_Tags{2}
            % "REV_BTH"
            Retro_No(i) =  2;
        case retro_Tags{3}
            % "REP_1ST"
            Retro_No(i) =  3;
        case retro_Tags{4}
            % "REP_2ND"
            Retro_No(i) =  4;
        case retro_Tags{5}
            % "DRP_BTH"
            Retro_No(i) =  5;
    end

end