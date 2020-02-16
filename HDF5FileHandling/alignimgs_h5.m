function [dX, dY] = alignimgs_h5(FixedImgName,Directory,refFrameIdx,MaxOffset,WindowSize,Verbose)
% function [dX, dY] = alignimgs_h5(FixedImgName,Directory,refFrameIdx,MaxOffset,WindowSize,Verbose)
% 1/24/2015: Gerry wrote it
% This function is based off of alignimgs4. Refer to that script for full
% changelog and documentation.
%
% This script has the same functionality, except utilizes uncompressed HDF5
% files for I/O, which allows faster, more efficient I/O, as well as no
% constratins on data size. Miji is no longer required.

% here we assume all data are in '/data'
ImgInfo = h5info(fullfile(Directory,FixedImgName),'/data'); % get info for only this variable
Width = ImgInfo.Dataspace.MaxSize(2);
Height = ImgInfo.Dataspace.MaxSize(1);
NumSlices = ImgInfo.Dataspace.MaxSize(3);

if isempty(MaxOffset) % set default max offset if not specified
    MaxOffset=10; % max movement allowed, in pixels
end
Method='redxcorr2normimages'; %alignment method

% read the ref slice / bolus of slices (to avg across)
tempimg = h5read(fullfile(Directory,FixedImgName),'/data',[1 1 refFrameIdx],[Height Width WindowSize]);
refImage = single(mean(tempimg,3));

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
        if a-1 > (NumSlices-WindowSize)
                % stick with your prev temp image the rest of the way
        else
            if a == StartIndices(aa)
                tempimg2 = h5read(fullfile(Directory,FixedImgName),'/data',[1 1 a],[Height Width WindowSize]);
            else
                % faster method: just read in the extra slice you need to
                % move the window
                tempimg3 = zeros(size(tempimg2));
                tempimg3(:,:,1:end-1) = tempimg2(:,:,2:end);
                tempimg3(:,:,end) = h5read(fullfile(Directory,FixedImgName),'/data',[1 1 a],[Height Width 1]);
                tempimg2 = tempimg3;
            end
        end
        FixedImg = single(mean(tempimg2,3)); % convert from uint16

        %--------------------------------------------------------------------------
        % fast
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

% create new file to store the aligned image
FinalHeight = Height-(MaxUp+MaxDown);
FinalWidth = Width-(MaxLeft+MaxRight);
h5create([fullfile(Directory,FixedImgName(1:end-3)) '_WinSize' num2str(WindowSize) '_aligned.h5'],'/data',[FinalHeight FinalWidth NumSlices],'Datatype','single');

% then apply the offsets
for b=1:NumSlices
    % read a slice
    FixedImg = h5read(fullfile(Directory,FixedImgName),'/data',[1 1 b],[Height Width 1]);

    % need to initialize this for later use
    FixedImgAligned = zeros(size(FixedImg)); 
    
    % shift image
    FixedImgAligned(iOverlapY(b,1):iOverlapY(b,2),iOverlapX(b,1):iOverlapX(b,2)) = FixedImg(jOverlapY(b,1):jOverlapY(b,2),jOverlapX(b,1):jOverlapX(b,2));
    
    % crop off zeros
    FixedImgAligned = FixedImgAligned(MaxUp+1:end-MaxDown,MaxLeft+1:end-MaxRight);
    FixedImgAligned = single(FixedImgAligned); % convert to single before writing
    
    % export
    h5write([fullfile(Directory,FixedImgName(1:end-3)) '_WinSize' num2str(WindowSize) '_aligned.h5'],'/data',FixedImgAligned,[1 1 b],[FinalHeight FinalWidth 1]);
end
end