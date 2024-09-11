% Read the existing Cogan lab lexical delay task parameters for reference
% Set the root directory
rootDir = 'C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay';
% Recursively search for all trialInfo.mat files in the directory and subdirectories
files = dir(fullfile(rootDir, '**', 'trialInfo.mat'));

% Initialize arrays to store calculated values
ISI_all = [];
resp_all = [];
stim_delay_all = [];

% Loop through each trialInfo.mat file
for fileIdx = 1:length(files)
    % Load the trialInfo.mat file
    filePath = fullfile(files(fileIdx).folder, files(fileIdx).name);
    load(filePath, 'trialInfo');
    
    % Loop through each cell in trialInfo
    for i = 1:length(trialInfo)
        % Calculate ISI, response time, and stimulus delay
        ISI = trialInfo{1, i}.isiEnd - trialInfo{1, i}.isiStart;
        resp = trialInfo{1, i}.respEnd - trialInfo{1, i}.respStart;
        stim_delay = trialInfo{1, i}.respStart - trialInfo{1, i}.audioStart;
        
        % Collect the calculated values
        ISI_all = [ISI_all, ISI];
        resp_all = [resp_all, resp];
        stim_delay_all = [stim_delay_all, stim_delay];
    end
end

% Plot histograms for ISI, response time, and stimulus delay
figure;
subplot(3,1,1);
histogram(ISI_all);
title('ISI Distribution');
xlabel('ISI (s)');
ylabel('Frequency');

subplot(3,1,2);
histogram(resp_all);
title('Response Window Length Distribution');
xlabel('Response Time (s)');
ylabel('Frequency');

subplot(3,1,3);
histogram(stim_delay_all);
title('Stimulus Delay Distribution');
xlabel('Stimulus Delay (s)');
ylabel('Frequency');

% Calculate mean and standard deviation for each variable
ISI_mean = mean(ISI_all);
ISI_std = std(ISI_all);
resp_mean = mean(resp_all);
resp_std = std(resp_all);
stim_delay_mean = mean(stim_delay_all);
stim_delay_std = std(stim_delay_all);

% Print the results
fprintf('ISI - Mean: %.4f, Std: %.4f\n', ISI_mean, ISI_std);
fprintf('Response Time Window - Mean: %.4f, Std: %.4f\n', resp_mean, resp_std);
fprintf('Stimulus Delay - Mean: %.4f, Std: %.4f\n', stim_delay_mean, stim_delay_std);