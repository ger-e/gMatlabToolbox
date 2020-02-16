function BatchwarpImages(ImgName,Directory,tempdir,RefFrame,warpingSettings)
% function BatchwarpImages(ImgName,Directory,tempdir,RefFrame,warpingSettings)
% 11/11/2015: Gerry wrote it
% This script will batch locally 'warp' your images based upon the code
% (warpImages.m) from Ahrens et al., 2013, Nat Methods. Note that I modified
% warpImages.m to allow for non-square sized chunks to be locally warped. In
% practice, it seems like squares still work best. 
%
% usage example: (see also warpImages.m)
% warpingSettings = [30 30 30 30 15 15];

mkdir(fullfile(Directory,tempdir)); % make temp directory
ImgInfo = imfinfo(fullfile(Directory,ImgName));
filesize = ImgInfo(1).FileSize; % to use appropriate method if exceeds 32-bit space

if filesize < 2^32
    NumSlices = length(ImgInfo);
else
    temp2 = strfind(ImgInfo.ImageDescription,'s=');
    NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));
end

% just need info from first index of ImgInfo struct
ImgInfo = ImgInfo(1);

if filesize < 2^32
    RefSlice = imread(fullfile(Directory,ImgName),'Index',RefFrame,'Info',ImgInfo);
else
    RefSlice = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,RefFrame,1);
end

if filesize < 2^32
    parfor a=1:NumSlices
        CurrSlice = imread(fullfile(Directory,ImgName),'Index',a,'Info',ImgInfo);
        
        % now perform local warping
        correctedImage = warpImages(single(RefSlice),single(CurrSlice),warpingSettings);
        
        % export the slice
        success = 0;
        while ~success
            try
                imwrite(uint16(correctedImage),fullfile(Directory,tempdir,[ImgName(1:end-4) '_warped' '_t' num2str(a,'%05d') '.tif']),'tiff','Compression','none');
                success = 1;
            catch
                fprintf(1,'\nWrite error, retrying...');
                pause(0.1);
            end
        end
    end
else
    parfor a=1:NumSlices
        CurrSlice = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,a,1);
        correctedImage = warpImages(single(RefSlice),single(CurrSlice),warpingSettings);
        success = 0;
        while ~success
            try
                imwrite(uint16(correctedImage),fullfile(Directory,tempdir,[ImgName(1:end-4) '_warped' '_t' num2str(a,'%05d') '.tif']),'tiff','Compression','none');
                success = 1;
            catch
                fprintf(1,'\nWrite error, retrying...');
                pause(0.1);
            end
        end        
    end
end

% then call MIJI to export to tiff stack, and clean up
FullTempDir = DuplicateChar(fullfile(Directory,tempdir),'\');
IJOutputDir = DuplicateChar(Directory,'\');

try % make sure MIJI is turned on
    MIJ.version;
catch
    fprintf(1,'\nMIJI not turned on...turning on...\n');
    Miji(false);
end

% now read virtual stack and then export tif stack
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' ImgName(1:end-4) '_warped_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' ImgName(1:end-4) '_warped.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');

end