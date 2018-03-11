% 32bitTo8bit
% 08/19/2010: Gerry wrote it
%
% This script will read in a tiff stack, convert it from whatever its
% current current bit type is (so long as it is unsigned) to 8-bit. NOTE:
% the function uint8 will not linearly scale values, rather it truncates
% values, therefore this function should be used instead.

rootDir = 'G:\Kurt\In vivo tiffs\test';
cd(rootDir);
addpath(pwd);

subDir = 'toConvert';

ImgList = dir(subDir);
cd(subDir);
ImgList = ImgList(3:end);

for a=1:length(ImgList)
    temp = LSMto4DMatrix(ImgList(a).name);
    temp = temp.*255./max(temp(:));
    temp = uint8(temp);
    for b=1:size(temp,3)
        % note that we're explicitly assuming that the image has only ONE
        % channel
        imwrite(temp(:,:,b),[ImgList(a).name '_uint8.tiff'],'tif','Compression','none','Resolution',[96 96],'WriteMode','append');
        clear temp;
    end
end