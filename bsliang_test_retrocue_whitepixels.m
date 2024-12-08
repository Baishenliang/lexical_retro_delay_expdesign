retro_Tags = ["REP_BTH","REV_BTH","REP_1ST","REP_2ND","DRP_BTH"];
for retro_Tag=retro_Tags
    % 1. Read the image
    imgpath = fullfile('D:','bsliang_Coganlabcode','Retrocue_taskscripts','stim','instructions',strjoin([retro_Tag,'.JPG'],''));
    img = imread(imgpath); % Replace with your image path
    
    % 2. Check if the image is in color (RGB), and if so, extract the channels
    if size(img, 3) == 3
        % Extract RGB channels
        red = img(:, :, 1);
        green = img(:, :, 2);
        blue = img(:, :, 3);
    
        % 3. Define the condition for white pixels (all RGB values close to 255)
        % Adjust the threshold to allow for slight variations, e.g., 240-255
        threshold = 240;
        isWhite = red > threshold & green > threshold & blue > threshold;
    else
        % If the image is grayscale
        threshold = 240;
        isWhite = img > threshold;
    end
    
    % 4. Calculate the white pixel ratio
    whitePixelCount = sum(isWhite(:)); % Number of white pixels
    
    % 5. Display the result
    fprintf(strjoin([retro_Tag,'\n'],""))
    fprintf('The numer of white pixels is: %.2f%\n', whitePixelCount);
    fprintf('\n')
end

% 20241208 results:

% REP_BTH
% The numer of white pixels is: 1667.00
% REV_BTH
% The numer of white pixels is: 1668.00
% REP_1ST
% The numer of white pixels is: 1488.00
% REP_2ND
% The numer of white pixels is: 1862.00
% DRP_BTH
% The numer of white pixels is: 1675.00

% star_size = 1675/2 = 837.5
% 1_size = 1488 - 837.5 = 650.5
% 2_size = 1862 - 837.5 = 1024.5

% the size of the star is between the sizes of 1 and 2, successful.