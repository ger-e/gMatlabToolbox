% XXbitTo8bit
% 08/19/2010: Gerry wrote it
% 05/05/2011: Gerry modified 32bitTo8bit to new name plus tiff stack write
% error control
%
% This script will read in a tiff stack, convert it from whatever its
% current current bit type is (so long as it is unsigned) to 8-bit. NOTE:
% the function uint8 will not linearly scale values, rather it truncates
% values, therefore this function should be used instead.

rootDir = 'G:\Kurt\In vivo tiffs';
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
        success = 0;
        while ~success
            try
                imwrite(temp(:,:,b),[ImgList(a).name '_uint8.tiff'],'tif','Compression','none','Resolution',[96 96],'WriteMode','append');
                success = 1;
            catch
                fprintf(1,'\nWrite Error, waiting 1sec to try again');
                fprintf(1,'\nIt was: Img %i Z%i', a, b);
                pause(1);
            end
        end
    end
    clear temp;   
end