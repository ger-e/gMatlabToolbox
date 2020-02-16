function BatchwarpImages2(ImgName,Directory,tempdir,refFrameIdx,WindowSize,warpingSettings)
% function BatchwarpImages2(ImgName,Directory,tempdir,refFrameIdx,WindowSize,warpingSettings)
% 11/11/2015: Gerry wrote it
% 11/12/2015: Gerry modified to allow for sliding-window based warping
% (because the warping result from just a single frame is crappy)
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
    tempimg = zeros(Height,Width,WindowSize);
else
    temp2 = strfind(ImgInfo.ImageDescription,'s=');
    NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));
end

% just need info from first index of ImgInfo struct
ImgInfo = ImgInfo(1);

% read the ref slice / bolus of slices (to avg across)
if filesize < 2^32
    for bb=1:WindowSize
        tempimg(:,:,bb) = imread(fullfile(Directory,ImgName),'Index',refFrameIdx+bb-1,'Info',ImgInfo);
    end    
else
    tempimg = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,refFrameIdx,WindowSize);
end
tempimg = mean(tempimg,3);
RefSlice = single(tempimg);

% specify parfor loop iteration conditions
NumWorkers = matlabpool('size');
FramesPerWorker = ceil(NumSlices/NumWorkers);
StartIndices = 1:FramesPerWorker:NumSlices;

parfor aa=1:length(StartIndices)
    StartA = StartIndices(aa);
    EndA = min([StartIndices(aa)+FramesPerWorker-1 NumSlices]);
    for a=StartA:EndA
        % read a slice or bolus of slices (to mean intensitys in moving window)
        if filesize < 2^32 % initialize this only for small file processing
            tempimg2 = zeros(Height,Width,WindowSize);
        end
        
        if a-1 > (NumSlices-WindowSize)
            if filesize > 2^32
                % stick with your prev temp image the rest of the way
    %             tempimg2 = ReadRawIJSlices(fullfile(Directory,FixedImgName),ImgInfo,NumSlices-WindowSize+1,WindowSize);
            else
%                 for b=1:WindowSize
%                     tempimg2(:,:,b) = imread(fullfile(Directory,FixedImgName),'Index',NumSlices-WindowSize+b);
%                 end
            end
        else
            if filesize > 2^32
                if a == StartIndices(aa)
                    tempimg2 = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,a,WindowSize);
                else
                    % faster method: just read in the extra slice you need to
                    % move the window
                    tempimg3 = zeros(size(tempimg2));
                    tempimg3(:,:,1:end-1) = tempimg2(:,:,2:end);
                    tempimg3(:,:,end) = ReadRawIJSlices(fullfile(Directory,ImgName),ImgInfo,a,1);
                    tempimg2 = tempimg3;
                end
            else
                for b=1:WindowSize
                    tempimg2(:,:,b) = imread(fullfile(Directory,ImgName),'Index',a+b-1);
                end
            end
        end
        CurrSliceMean = single(mean(tempimg2,3)); % convert from uint16
        
        % -----------------------------------------------------------------
        % now calculate the warping and apply transformation
        [~,xyShift] = warpImages(RefSlice,CurrSliceMean,warpingSettings);
        if a-1 > (NumSlices-WindowSize) % edge condition: you've kept the same tempimg2, but need to take the proper slice
            CurrSlice = tempimg2(:,:,a-(NumSlices-WindowSize));
        else
            CurrSlice = tempimg2(:,:,1); % the first slice is the one you want to apply transformation to, so long as you're not in the edge condition
        end
        CurrSlice = CurrSlice(:);
        CurrSlice = CurrSlice(xyShift);
        CurrSlice = reshape(CurrSlice,size(tempimg2,1),size(tempimg2,2));
        
        % now export the slice
        success = 0;
        while ~success
            try
                imwrite(uint16(CurrSlice),fullfile(Directory,tempdir,[ImgName(1:end-4) '_warped' '_t' num2str(a,'%05d') '.tif']),'tiff','Compression','none');
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
MIJ.run('Save',['path=[' IJOutputDir '\\' ImgName(1:end-4) '_WinSize' num2str(WindowSize) '_warped.tif]']);

% clean up tif series
[success, message, msgID] = rmdir(fullfile(Directory,tempdir),'s');
end