% NormalizeByMean.m
% 08/22/2011: Gerry wrote it
%
% This script will take in a set of images and output a set of normalized
% images. Normalization is performed by dividing each image by its mean,
% and then scaling by the highest (new) value across the set of all images.
% One can very easily adapt this to take the median as opposed to the mean.
InputDir = 'D:\Gerry\SEBI norm\COMPLETELY ALIGNED 060311-08 35dai hippo anterior cropped tracings'; % absolute path to folder containing images
FileFormat = '.tif'; % image file format
bitLevel = 8; % e.g. 8, 16, 32-bit

cd(InputDir)
ImgList = dir(['*' FileFormat]);

% first get the max normalized intensity across all images
fprintf('\nFinding max intensity to normalize by');
MaxIntensity = 0;
for a=1:length(ImgList)
    CurrImg = imread(ImgList(a).name); % read in the img
    CurrImg = double(CurrImg); % change datatype so we can manipulate it
    CurrImg = CurrImg./mean(CurrImg(:)); % normalize by mean intensity
    CurrMaxIntensity = max(CurrImg(:));
    if CurrMaxIntensity>MaxIntensity
        MaxIntensity = CurrMaxIntensity;
    end
    if mod(a,50)
        fprintf('.');
    else
        fprintf('%d\n.',a);
    end
end
fprintf('Done!');

% then perform the normalization proper
fprintf('\nNormalizing');
for b=1:length(ImgList)
    CurrImg = imread(ImgList(b).name); % read in the img
    CurrImg = double(CurrImg); % change datatype so we can manipulate it
    CurrImg = CurrImg./mean(CurrImg(:)); % normalize by mean intensity
    CurrImg = CurrImg./MaxIntensity.*(2^bitLevel-1); % rescale based upon the bit level
    eval(['CurrImg = uint' num2str(bitLevel) '(CurrImg);']); % change datatype to appropriate bit level, unsigned
    success = 0;
    while ~success % then output the normalized image
        try
            imwrite(CurrImg,['normBymean_' ImgList(b).name],'tiff','Compression','none','Resolution',[96 96]);
            success = 1;
        catch
            fprintf('\nWrite Error, waiting 2sec to try again\n');
            pause(2);
        end
    end
    if mod(b,50)
        fprintf('.');
    else
        fprintf('%d\n.',b);
    end    
end
fprintf('Done!');