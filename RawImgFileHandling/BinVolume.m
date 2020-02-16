function data3 = BinVolume(filename,Directory)
% function data3 = BinVolume(filename,Directory)
% 2/27/2015: Gerry wrote it
% This function will read in your raw datafile and then take the mean
% intensity across the entire imaged volume for each given time point; i.e.
% if you acquired 6 slices per time point, then we will take the mean
% across those whole 6 slices to yield just one value. Output data3 is a
% vector

fullname = fullfile(Directory,filename);

% get basic img parameters
[dummy, ini] = readrawfile_gerry(fullname,[],1);

% frame skip points
skipframes = 0:ini.Piezo_fpc:ini.totalframes;

framesPerC = ini.Piezo_fpc; % just pass this value to parfor
data3 = zeros(length(skipframes),1); % initialize

% read in an imaged volume time point at a time
parfor a=1:length(skipframes)
    data = readrawfile_gerry(fullname,skipframes(a),framesPerC);
    data2 = mean(data(:));
    data3(a) = data2; 
end
end