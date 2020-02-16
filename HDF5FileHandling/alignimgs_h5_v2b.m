function alignimgs_h5_v2b(ImgName,Directory,refFrameIdx,MaxOffset,WindowSize,Verbose)
% function alignimgs_h5_v2(ImgName,Directory,refFrameIdx,MaxOffset,WindowSize,Verbose)
% 1/24/2015: Gerry wrote it
% This function is based off of alignimgs4. Refer to that script for full
% changelog and documentation for 2015 version.
% 1/1/2016: Gerry modified significantly to only export the offset values
% for alignment (and also read in the offset values for interlacing). Image
% processing is now done on the ENTIRE dataset at once. Parallel processing
% is still done within each slice to allow for best scalability
% Additional optimizations include
% 1) more efficient sliding window reading of additional frames (plus
% bugfix whereby the wrong index was being taken), allowing for neglibile
% increase in processing time with larger window sizes
% 2) more efficient mean image calculation
% 3) more efficient parallel processing (parfor on the slices, not on the
% frames)
%
% refFrameIdx to a single frame; MaxOffset in pixels; WindowSize in pixels
% 
% Note: all variables added to hdf5 file will be written with chunking and
% infinite dimensions, to allow greatest future flexibity because variables
% cannot be deleted in hdf5 files
% Note: there are limits to the values that can be had for certain values,
% due to the datatype (e.g. uint8, uint16, int8, etc)

fullpath = fullfile(Directory,ImgName); % just so we can save a bit of time in the loop

% load in required metadata
% here we assume all img data are in '/data'
ImgInfo = h5info(fullpath,'/data'); % get info for only this variable
Width = ImgInfo.Dataspace.MaxSize(2);
Height = ImgInfo.Dataspace.MaxSize(1);
SlicesToUse = double(h5read(fullpath,'/SlicesToUse')); %1:20
SliceIndices = h5read(fullpath,'/SliceIndices');
AllOffsets = h5read(fullpath,'/AllOffsets');
AllPostFirstFlag = h5read(fullpath,'/AllPostFirstFlag');
MaxInterlaceOffset = max(AllOffsets(:));
NumFramesPerSlice = size(SliceIndices,2);

if isempty(refFrameIdx) % default refFrameIdx is in the middle
    refFrameIdx = floor(NumFramesPerSlice/2);
end

if isempty(MaxOffset) % set default max offset if not specified
    MaxOffset=10; % max movement allowed, in pixels
end
Method='redxcorr2normimages'; %alignment method

% initialize variables here and in the hdf5 file
AlliOverlapX = zeros(size(SliceIndices,2),2,size(SliceIndices,1)); 
AlliOverlapY = zeros(size(SliceIndices,2),2,size(SliceIndices,1)); 
AlljOverlapX = zeros(size(SliceIndices,2),2,size(SliceIndices,1)); 
AlljOverlapY = zeros(size(SliceIndices,2),2,size(SliceIndices,1)); 
MaxLeft = zeros(length(SlicesToUse),1);
MaxRight = zeros(length(SlicesToUse),1);
MaxUp = zeros(length(SlicesToUse),1);
MaxDown = zeros(length(SlicesToUse),1);
if ~h5dataexists('AlliOverlapX',h5info(fullpath)) % note precision here: can't have more than 2^16 pixels along a given dimension
    h5create(fullpath,'/AlliOverlapX',[Inf Inf Inf],'ChunkSize',[1 2 10],'Datatype','uint16'); 
end
if ~h5dataexists('AlliOverlapY',h5info(fullpath))
    h5create(fullpath,'/AlliOverlapY',[Inf Inf Inf],'ChunkSize',[1 2 10],'Datatype','uint16');
end
if ~h5dataexists('AlljOverlapX',h5info(fullpath))
    h5create(fullpath,'/AlljOverlapX',[Inf Inf Inf],'ChunkSize',[1 2 10],'Datatype','uint16');
end
if ~h5dataexists('AlljOverlapY',h5info(fullpath))
    h5create(fullpath,'/AlljOverlapY',[Inf Inf Inf],'ChunkSize',[1 2 10],'Datatype','uint16');
end
if ~h5dataexists('MaxLeft',h5info(fullpath)) % note precision here: can only have at most a -128 to 127 displacement!
    h5create(fullpath,'/MaxLeft',[Inf Inf],'ChunkSize',[1 1],'Datatype','int8');
end
if ~h5dataexists('MaxRight',h5info(fullpath))
    h5create(fullpath,'/MaxRight',[Inf Inf],'ChunkSize',[1 1],'Datatype','int8');
end
if ~h5dataexists('MaxUp',h5info(fullpath))
    h5create(fullpath,'/MaxUp',[Inf Inf],'ChunkSize',[1 1],'Datatype','int8');
end
if ~h5dataexists('MaxDown',h5info(fullpath))
    h5create(fullpath,'/MaxDown',[Inf Inf],'ChunkSize',[1 1],'Datatype','int8');
end

parfor f=1:length(SlicesToUse)
    % read the ref slice / bolus of slices (to avg across)
    CountG = 1;
    for g=refFrameIdx:refFrameIdx-1+WindowSize
        StartIndx = SliceIndices(f,g);
        SliceOut = applyinterlacing_h5(MaxInterlaceOffset,Height,Width,fullpath,StartIndx,AllOffsets(f,g),AllPostFirstFlag(f,g));
        if g==refFrameIdx
            tempimg = zeros(size(SliceOut,1),size(SliceOut,2),WindowSize,'uint16');
        end
        tempimg(:,:,CountG) = SliceOut;
        CountG = CountG + 1;
    end
    refImage = single(mean(tempimg,3)); % 'mean' auto-converts to double
%     refImage = refImage(floor(size(refImage,1)/2)-128:floor(size(refImage,1)/2)+128,floor(size(refImage,2)/2)-128:floor(size(refImage,2)/2)+128);
    dYTemp = zeros(1,NumFramesPerSlice);
    dXTemp = zeros(1,NumFramesPerSlice);
    iOverlapXTemp = zeros(NumFramesPerSlice,2);
    iOverlapYTemp = zeros(NumFramesPerSlice,2);
    jOverlapXTemp = zeros(NumFramesPerSlice,2);
    jOverlapYTemp = zeros(NumFramesPerSlice,2);
        
    for a=1:NumFramesPerSlice 
        % first get offsets
        if a-1 > (NumFramesPerSlice-WindowSize)
            % stick with your prev temp image the rest of the way
        else
            if a == 1
                CountG = 1;
                ReplaceSlice = 1;
                for g=a:WindowSize
                    StartIndx = SliceIndices(f,g);
                    SliceOut = applyinterlacing_h5(MaxInterlaceOffset,Height,Width,fullpath,StartIndx,AllOffsets(f,g),AllPostFirstFlag(f,g));
                    if g==a
                        tempimg2 = zeros(size(SliceOut,1),size(SliceOut,2),WindowSize,'uint16');
                    end
                    tempimg2(:,:,CountG) = SliceOut;
                    CountG = CountG + 1;
                end
                OldSum = sum(tempimg2,3,'double'); % 16-bits not enough to hold the sum!
                CurrSum = OldSum;
            else
                % fastest method: just read in the extra slice you need to
                % move the window, but not worrying about order per se
                SliceReplaced = tempimg2(:,:,ReplaceSlice); %uint16
                StartIndx = SliceIndices(f,a-1+WindowSize);
                tempimg2(:,:,ReplaceSlice) = applyinterlacing_h5(MaxInterlaceOffset,Height,Width,fullpath,StartIndx,AllOffsets(f,a),AllPostFirstFlag(f,a)); %uint16
                CurrSum = (OldSum-double(SliceReplaced)+double(tempimg2(:,:,ReplaceSlice))); % double
                ReplaceSlice = ReplaceSlice + 1;
                if ReplaceSlice > WindowSize
                    ReplaceSlice = 1;
                end
            end
        end
        FixedImg = single(CurrSum)./WindowSize; % single--keep as single; the following calc will be faster
        OldSum = CurrSum; %double

        % now do the alignment calculation
        unalignedFrame = FixedImg; %FixedImg(floor(size(FixedImg,1)/2)-128:floor(size(FixedImg,1)/2)+128,floor(size(FixedImg,2)/2)-128:floor(size(FixedImg,2)/2)+128);
        if std(unalignedFrame(:))~=0 % in case a blank frame existed in original datafile
            [dYTemp(a),dXTemp(a),~,~,cmax]= fcn_calc_relative_offset(refImage,unalignedFrame,Method,MaxOffset,0);
            if Verbose
                disp(['Inter-trial alignment: ' 'Frame ' num2str(a) filesep num2str(size(FixedImg,3)) '. XOffset: ' num2str(dXTemp(a)) ', YOffset: ' ...
                num2str(dYTemp(a)) ', Cmax: ' num2str(cmax)]);
            end

            [iOverlapXTemp(a,:),iOverlapYTemp(a,:),~,jOverlapXTemp(a,:),jOverlapYTemp(a,:)]=...
            fcn_get_overlap(1,1,0,size(FixedImg,2),size(FixedImg,1),0,dXTemp(a)+1,dYTemp(a)+1,0,size(FixedImg,2),size(FixedImg,1),0);
        else
            dYTemp(a) = 0; dXTemp(a) = 0;
            iOverlapXTemp(a,:) = [0 0]; iOverlapYTemp(a,:) = [0 0];
            jOverlapXTemp(a,:) = [0 0]; jOverlapYTemp(a,:) = [0 0];
        end
    end
    AlliOverlapX(:,:,f) = iOverlapXTemp;
    AlliOverlapY(:,:,f) = iOverlapYTemp;
    AlljOverlapX(:,:,f) = jOverlapXTemp;
    AlljOverlapY(:,:,f) = jOverlapYTemp;
    
    % figure out the max displacements to crop 0's out later
    MaxLeft(f) = max(dXTemp(:));
    MaxRight(f) = abs(min(dXTemp(:)));
    MaxUp(f) = max(dYTemp(:));
    MaxDown(f) = abs(min(dYTemp(:)));
end

% save testalignrun AlliOverlapX AlliOverlapY AlljOverlapX AlljOverlapY MaxLeft MaxRight MaxUp MaxDown;
h5write(fullpath,'/AlliOverlapX',AlliOverlapX,[1 1 1],size(AlliOverlapX));
h5write(fullpath,'/AlliOverlapY',AlliOverlapY,[1 1 1],size(AlliOverlapY));
h5write(fullpath,'/AlljOverlapX',AlljOverlapX,[1 1 1],size(AlljOverlapX));
h5write(fullpath,'/AlljOverlapY',AlljOverlapY,[1 1 1],size(AlljOverlapY));
h5write(fullpath,'/MaxLeft',MaxLeft,[1 1],size(MaxLeft));
h5write(fullpath,'/MaxRight',MaxRight,[1 1],size(MaxRight));
h5write(fullpath,'/MaxUp',MaxUp,[1 1],size(MaxUp));
h5write(fullpath,'/MaxDown',MaxDown,[1 1],size(MaxDown));

% store the parameters used for alignment
if ~h5dataexists('AlignWinSize',h5info(fullpath))
    h5create(fullpath,'/AlignWinSize',1,'Datatype','uint32');
end
h5write(fullpath,'/AlignWinSize',WindowSize);
if ~h5dataexists('refFrameIdx',h5info(fullpath))
    h5create(fullpath,'/refFrameIdx',1,'Datatype','uint32');
end
h5write(fullpath,'/refFrameIdx',refFrameIdx);
if ~h5dataexists('MaxAlignmentOffset',h5info(fullpath))
    h5create(fullpath,'/MaxAlignmentOffset',1,'Datatype','uint32');
end
h5write(fullpath,'/MaxAlignmentOffset',MaxOffset);

end