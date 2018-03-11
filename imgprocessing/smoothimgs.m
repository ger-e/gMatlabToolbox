function smoothimgs(ImgName,Directory,tempdir,FilterSize)
% function smoothimgs(ImgName,Directory,tempdir,FilterSize)
% 6/8/2015: Gerry wrote it
%
% This script will take in a tif stack and smooth it with a 2D average
% filter of size FilterSize. It will then output the smoothed stack. Note
% that we assume input is uint16, and we export output with rounded values
% of uint16

% open matlab pool if it's not already
if ~matlabpool('size')
    matlabpool open;
end

% get img info
mkdir(fullfile(Directory,tempdir)); % make temp directory
ImgInfo = imfinfo(fullfile(Directory,ImgName));
filesize = ImgInfo(1).FileSize; % to use appropriate method if exceeds 32-bit space

if filesize < 2^32
    NumSlices = length(ImgInfo);
else
    % get number of slices from ImageJ header
    temp2 = strfind(ImgInfo.ImageDescription,'s=');
    NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));
end

% now do the filtering
parfor a=1:NumSlices
    if filesize > 2^32
        tempimg = ReadRawIJSlice(fullfile(Directory,ImgName),a);
    else
        tempimg = imread(fullfile(Directory,ImgName),'Index',a);
    end
    H = fspecial('average',FilterSize); % default hsize is [3 3]
    filteredimg = imfilter(tempimg,H);
    
    % now export (imfilter rounds to and maintains input datatype, i.e. uint16; shouldn't need a range adj b/c avg filter will never give you values that exceed 2^16)
    success = 0;
    while ~success
        try
            imwrite(filteredimg,fullfile(Directory,tempdir,[ImgName(1:end-4) '_smooth' num2str(FilterSize(1)) 'x' num2str(FilterSize(2)) '_t' num2str(a,'%05d') '.tif']),'Compression','none');
            success = 1;
        catch
            fprintf(1,'\nWrite error, retrying...');
            pause(0.1);
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
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' ImgName(1:end-4) '_smooth' num2str(FilterSize(1)) 'x' num2str(FilterSize(2)) '_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' ImgName(1:end-4) '_smooth' num2str(FilterSize(1)) 'x' num2str(FilterSize(2)) '.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');
end