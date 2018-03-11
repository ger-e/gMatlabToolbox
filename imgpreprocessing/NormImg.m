% NormImg.m
% This script will take an input of an image and apply quantile
% normalization to it.  Note that you will have to modify the script based
% upon whether certain numbers of channels/time points/slices are present,
% as the input image is a tiff series NOT and LSM

% edit these
InputDir = '\\192.168.0.138\temp\Normalize';
OutputDir = '\\192.168.0.138\temp\output';
NumChannels = 1;
NumTimePts = 13;
NumSlices = 43;
XDim = 431;
YDim = 392;

% load images
fprintf(1,'\nLoading images...');
cd(InputDir);
ImgList = dir('*.tif');
temp = imread(ImgList(1).name);
AllImgs = zeros(length(temp(:)),NumSlices*NumChannels*NumTimePts);
AllIndices = AllImgs; % keep track of indices

for a=1:NumSlices*NumChannels*NumTimePts
    temp2 = imread(ImgList(a).name);
    temp2 = temp2(:); % linearize matrix for proper feeding to quantilenorm
    CurrentSeed = sum(clock*100);
    rand('state',CurrentSeed); % set random seed
    temp2 = Shuffle(temp2); % randomize for better normalization
    rand('state',CurrentSeed); % set random seed
    temp3 = Shuffle(1:length(temp2))'; % use same randomization
    AllImgs(:,a) = temp2;
    AllIndices(:,a) = temp3;
end
fprintf(1,'Done!');

% normalize
fprintf(1,'\nPerforming normalization...');
AllImgsNorm = quantilenorm(AllImgs);
fprintf(1,'Done! \nExporting...');

% export
cd(OutputDir);
for b=1:NumSlices*NumChannels*NumTimePts
    % recover proper image order
    OutputImg = [AllImgsNorm(:,b) AllIndices(:,b)]; 
    OutputImg = sortrows(OutputImg,2);
    OutputImg = OutputImg(:,1);
    OutputImg = reshape(OutputImg,YDim,XDim);
    % now write the image
    imwrite(uint8(OutputImg),[ImgList(b).name(1:end-4) '_norm.tif'],'tif','Compression','none','Resolution',[96 96]);
end
fprintf(1,'Done!\n');