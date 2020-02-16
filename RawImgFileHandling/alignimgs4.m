function [dX, dY] = alignimgs4(FixedImgName,Directory,tempdir,refFrameIdx,MaxOffset,WindowSize,Verbose)
% function [dX, dY] = alignimgs4(FixedImgName,Directory,tempdir,refFrameIdx,MaxOffset,WindowSize,Verbose)
% 12/17/2014: Gerry wrote it, then made a modified version to allow
% operation on arbitrarily large datafiles. This means that the aligned
% image will not be returned; rather exported to a tif stack
% 12/18/2014: modified again to improve file handling speed. Removed demon
% registration method option. Script now utilizes parfor and MIJI
% (FIJI/Matlab implementation) for massive speed up of computations and
% file handling, respectively. Note as currently written, we can only
% handle 99999 frames per stack (filenaming)
% 12/23/2014: Gerry modified (3b version) to allow reading >4GB tif files
% as outputted by ImageJ (these are actually raw files)
% 1/16/2015: Gerry modified to allow moving window-based alignment (helps
% when you have very little signal) as well as ability to use appropriate
% method to read in images of any size; also put in failsafe mechanism for
% when processing a blank frame (sometimes raw image will have blank frames
% outputted from acquisition software)
% 1/17/2015: Gerry modified to use better version of ReadRawIJSlice
% (faster), plus a better algorithm for reading in slices for moving window
% (only read in the newest slice, as opposed to reading in all slices
% again; see adjstartdelay_interlacing4.m for additional notes]
%
% This script will take in an x by y by t image and align each frame (along
% t) to some reference frame, using only rigid-body transformations.
%
% 1) FixedImg: matrix containing your image, likely processed by
% adjstartdelay_interlacing2.m to fix interlacing issues due to scan mirror
% 2) Directory: full path to your input stack
% 3) tempdir: required name of temporary directory for saving tif series
% intermediates
% 4) refFrameIdx: index to the frame in FixedImg that you wish to align to
% (currently I have not built in the ability to align across images from
% different acquisitions)
% 5) MaxOffset: (applies to method 1 only, pass [] otherwise) default = 10;
% number of pixels neighborhood to allow searching for alignment. The
% higher the slower the algorithm
% 6) Verbose: pass 0 if you don't want to see progress

mkdir(fullfile(Directory,tempdir)); % make temp directory
ImgInfo = imfinfo(fullfile(Directory,FixedImgName));
filesize = ImgInfo(1).FileSize; % to use appropriate method if exceeds 32-bit space
Height=ImgInfo(1).Height;
Width=ImgInfo(1).Width;

if filesize < 2^32
    NumSlices = length(ImgInfo);
    tempimg = zeros(Height,Width,WindowSize);
else
    % get number of slices from ImageJ header
    temp2 = strfind(ImgInfo.ImageDescription,'s=');
    NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));
end

if isempty(MaxOffset) % set default max offset if not specified
    MaxOffset=10; % max movement allowed, in pixels
end
Method='redxcorr2normimages'; %alignment method

% read the ref slice / bolus of slices (to avg across)

if filesize > 2^32
    tempimg = ReadRawIJSlices(fullfile(Directory,FixedImgName),ImgInfo,refFrameIdx,WindowSize);
else
    for b=1:WindowSize
        tempimg(:,:,b) = imread(fullfile(Directory,FixedImgName),'Index',refFrameIdx+b-1);
    end
end
tempimg = mean(tempimg,3);
refImage = single(tempimg);

% initialize storage
% dY = zeros(NumSlices,1);
% dX = zeros(NumSlices,1);
% iOverlapX = zeros(NumSlices,2);
% iOverlapY = zeros(NumSlices,2);
% jOverlapX = zeros(NumSlices,2);
% jOverlapY = zeros(NumSlices,2);

% specify parfor loop iteration conditions
NumWorkers = matlabpool('size');
FramesPerWorker = ceil(NumSlices/NumWorkers);
StartIndices = 1:FramesPerWorker:NumSlices;

parfor aa=1:length(StartIndices)
    StartA = StartIndices(aa);
    EndA = min([StartIndices(aa)+FramesPerWorker-1 NumSlices]);
    dYTemp = zeros(1,EndA-StartA+1);
    dXTemp = zeros(1,EndA-StartA+1);
    iOverlapXTemp = zeros(EndA-StartA+1,2);
    iOverlapYTemp = zeros(EndA-StartA+1,2);
    jOverlapXTemp = zeros(EndA-StartA+1,2);
    jOverlapYTemp = zeros(EndA-StartA+1,2);
    
    % first get offsets
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
                for b=1:WindowSize
                    tempimg2(:,:,b) = imread(fullfile(Directory,FixedImgName),'Index',NumSlices-WindowSize+b);
                end
            end
        else
            if filesize > 2^32
                if a == StartIndices(aa)
                    tempimg2 = ReadRawIJSlices(fullfile(Directory,FixedImgName),ImgInfo,a,WindowSize);
                else
                    % faster method: just read in the extra slice you need to
                    % move the window
                    tempimg3 = zeros(size(tempimg2));
                    tempimg3(:,:,1:end-1) = tempimg2(:,:,2:end);
                    tempimg3(:,:,end) = ReadRawIJSlices(fullfile(Directory,FixedImgName),ImgInfo,a,1);
                    tempimg2 = tempimg3;
                end
            else
                for b=1:WindowSize
                    tempimg2(:,:,b) = imread(fullfile(Directory,FixedImgName),'Index',a+b-1);
                end
            end
        end
        FixedImg = single(mean(tempimg2,3)); % convert from uint16

        %--------------------------------------------------------------------------
        % Rainer Friedrich lab script: fast
        unalignedFrame = FixedImg;
        if std(unalignedFrame(:))~=0 % in case a blank frame existed in original datafile
            [dYTemp(a-StartA+1),dXTemp(a-StartA+1),~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
            if Verbose
                disp(['Inter-trial alignment: ' 'Frame ' num2str(a-StartA+1) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dXTemp(a-StartA+1)) ', YOffset: ' ...
                num2str(dYTemp(a-StartA+1)) ', Cmax: ' num2str(cmax)]);
            end

            [iOverlapXTemp(a-StartA+1,:),iOverlapYTemp(a-StartA+1,:),~,jOverlapXTemp(a-StartA+1,:),jOverlapYTemp(a-StartA+1,:)]=...
            fcn_get_overlap(...
            1,1,0,Width,Height,0,dXTemp(a-StartA+1)+1,dYTemp(a-StartA+1)+1,0,Width,Height,0);
        else
            dYTemp(a-StartA+1) = 0; dXTemp(a-StartA+1) = 0;
            iOverlapXTemp(a-StartA+1,:) = [0 0]; iOverlapYTemp(a-StartA+1,:) = [0 0];
            jOverlapXTemp(a-StartA+1,:) = [0 0]; jOverlapYTemp(a-StartA+1,:) = [0 0];
        end
    end
    % need to store data this way because of parfor restrictions
    dXStruct(aa).data = dXTemp;
    dYStruct(aa).data = dYTemp;
    iOverlapXStruct(aa).data = iOverlapXTemp;
    iOverlapYStruct(aa).data = iOverlapYTemp;
    jOverlapXStruct(aa).data = jOverlapXTemp;
    jOverlapYStruct(aa).data = jOverlapYTemp;
end

% reconstitute data matrices
dX = []; dY = [];
iOverlapX = []; iOverlapY = [];
jOverlapX = []; jOverlapY = [];
for d=1:length(StartIndices)
    dX = [dX dXStruct(d).data];
    dY = [dY dYStruct(d).data];
    iOverlapX = [iOverlapX' iOverlapXStruct(d).data']';
    iOverlapY = [iOverlapY' iOverlapYStruct(d).data']';
    jOverlapX = [jOverlapX' jOverlapXStruct(d).data']';
    jOverlapY = [jOverlapY' jOverlapYStruct(d).data']';
end

% figure out the max displacements to crop 0's out later
MaxLeft = max(dX(:));
MaxRight = abs(min(dX(:)));
MaxUp = max(dY(:));
MaxDown = abs(min(dY(:)));

% then apply the offsets
parfor b=1:NumSlices
    % read a slice
    if filesize < 2^32
        FixedImg = imread(fullfile(Directory,FixedImgName),'Index',b);
    else
        FixedImg = ReadRawIJSlices(fullfile(Directory,FixedImgName),ImgInfo,b,1);
    end
    
    FixedImg = single(FixedImg); % convert from uint16

    % need to initialize this for later use
    FixedImgAligned = zeros(size(FixedImg)); 
    
    % shift image
    FixedImgAligned(iOverlapY(b,1):iOverlapY(b,2),iOverlapX(b,1):iOverlapX(b,2)) = FixedImg(jOverlapY(b,1):jOverlapY(b,2),jOverlapX(b,1):jOverlapX(b,2));
    
    % crop off zeros
    FixedImgAligned = FixedImgAligned(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight);
    
    success = 0;
    while ~success
        try
            imwrite(uint16(FixedImgAligned),fullfile(Directory,tempdir,[FixedImgName(1:end-4) '_aligned' '_t' num2str(b,'%05d') '.tif']),'Compression','none');
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
MIJ.run('Image Sequence...', ['open=' FullTempDir '\\' FixedImgName(1:end-4) '_aligned_t00001.tif sort use']);
MIJ.run('Save',['path=[' IJOutputDir '\\' FixedImgName(1:end-4) '_WinSize' num2str(WindowSize) '_aligned.tif]']);

% clean up tif series
[success message msgID] = rmdir(fullfile(Directory,tempdir),'s');
end